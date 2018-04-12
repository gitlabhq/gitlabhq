import successSvg from 'icons/_icon_status_success.svg';
import warningSvg from 'icons/_icon_status_warning.svg';
import simplePoll from '~/lib/utils/simple_poll';
import MergeRequest from '../../../merge_request';
import Flash from '../../../flash';
import statusIcon from '../mr_widget_status_icon.vue';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetReadyToMerge',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      removeSourceBranch: this.mr.shouldRemoveSourceBranch,
      mergeWhenBuildSucceeds: false,
      useCommitMessageWithDescription: false,
      setToMergeWhenPipelineSucceeds: false,
      showCommitMessageEditor: false,
      isMakingRequest: false,
      isMergingImmediately: false,
      commitMessage: this.mr.commitMessage,
      successSvg,
      warningSvg,
    };
  },
  components: {
    statusIcon,
  },
  computed: {
    shouldShowMergeWhenPipelineSucceedsText() {
      return this.mr.isPipelineActive;
    },
    commitMessageLinkTitle() {
      const withDesc = 'Include description in commit message';
      const withoutDesc = "Don't include description in commit message";

      return this.useCommitMessageWithDescription ? withoutDesc : withDesc;
    },
    status() {
      const { pipeline, isPipelineActive, isPipelineFailed, hasCI, ciStatus } = this.mr;

      if (hasCI && !ciStatus) {
        return 'failed';
      } else if (!pipeline) {
        return 'success';
      } else if (isPipelineActive) {
        return 'pending';
      } else if (isPipelineFailed) {
        return 'failed';
      }

      return 'success';
    },
    mergeButtonClass() {
      const defaultClass = 'btn btn-sm btn-success accept-merge-request';
      const failedClass = `${defaultClass} btn-danger`;
      const inActionClass = `${defaultClass} btn-info`;

      if (this.status === 'failed') {
        return failedClass;
      } else if (this.status === 'pending') {
        return inActionClass;
      }

      return defaultClass;
    },
    iconClass() {
      if (this.status === 'failed' || !this.commitMessage.length || !this.mr.isMergeAllowed || this.mr.preventMerge) {
        return 'warning';
      }
      return 'success';
    },
    mergeButtonText() {
      if (this.isMergingImmediately) {
        return 'Merge in progress';
      } else if (this.shouldShowMergeWhenPipelineSucceedsText) {
        return 'Merge when pipeline succeeds';
      }

      return 'Merge';
    },
    shouldShowMergeOptionsDropdown() {
      return this.mr.isPipelineActive && !this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    isMergeButtonDisabled() {
      const { commitMessage } = this;
      return Boolean(!commitMessage.length
        || !this.shouldShowMergeControls()
        || this.isMakingRequest
        || this.mr.preventMerge);
    },
    isRemoveSourceBranchButtonDisabled() {
      return this.isMergeButtonDisabled;
    },
    shouldShowSquashBeforeMerge() {
      const { commitsCount, enableSquashBeforeMerge } = this.mr;
      return enableSquashBeforeMerge && commitsCount > 1;
    },
  },
  methods: {
    shouldShowMergeControls() {
      return this.mr.isMergeAllowed || this.shouldShowMergeWhenPipelineSucceedsText;
    },
    updateCommitMessage() {
      const cmwd = this.mr.commitMessageWithDescription;
      this.useCommitMessageWithDescription = !this.useCommitMessageWithDescription;
      this.commitMessage = this.useCommitMessageWithDescription ? cmwd : this.mr.commitMessage;
    },
    toggleCommitMessageEditor() {
      this.showCommitMessageEditor = !this.showCommitMessageEditor;
    },
    handleMergeButtonClick(mergeWhenBuildSucceeds, mergeImmediately) {
      // TODO: Remove no-param-reassign
      if (mergeWhenBuildSucceeds === undefined) {
        mergeWhenBuildSucceeds = this.mr.isPipelineActive; // eslint-disable-line no-param-reassign
      } else if (mergeImmediately) {
        this.isMergingImmediately = true;
      }

      this.setToMergeWhenPipelineSucceeds = mergeWhenBuildSucceeds === true;

      const options = {
        sha: this.mr.sha,
        commit_message: this.commitMessage,
        merge_when_pipeline_succeeds: this.setToMergeWhenPipelineSucceeds,
        should_remove_source_branch: this.removeSourceBranch === true,
      };

      // Only truthy in EE extension of this component
      if (this.setAdditionalParams) {
        this.setAdditionalParams(options);
      }

      this.isMakingRequest = true;
      this.service.merge(options)
        .then(res => res.data)
        .then((data) => {
          const hasError = data.status === 'failed' || data.status === 'hook_validation_error';

          if (data.status === 'merge_when_pipeline_succeeds') {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else if (data.status === 'success') {
            this.initiateMergePolling();
          } else if (hasError) {
            eventHub.$emit('FailedToMerge', data.merge_error);
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          new Flash('Something went wrong. Please try again.'); // eslint-disable-line
        });
    },
    initiateMergePolling() {
      simplePoll((continuePolling, stopPolling) => {
        this.handleMergePolling(continuePolling, stopPolling);
      });
    },
    handleMergePolling(continuePolling, stopPolling) {
      this.service.poll()
        .then(res => res.data)
        .then((data) => {
          if (data.state === 'merged') {
            // If state is merged we should update the widget and stop the polling
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('FetchActionsContent');
            MergeRequest.setStatusBoxToMerged();
            MergeRequest.hideCloseButton();
            MergeRequest.decreaseCounter();
            stopPolling();

            // If user checked remove source branch and we didn't remove the branch yet
            // we should start another polling for source branch remove process
            if (this.removeSourceBranch && data.source_branch_exists) {
              this.initiateRemoveSourceBranchPolling();
            }
          } else if (data.merge_error) {
            eventHub.$emit('FailedToMerge', data.merge_error);
            stopPolling();
          } else {
            // MR is not merged yet, continue polling until the state becomes 'merged'
            continuePolling();
          }
        })
        .catch(() => {
          new Flash('Something went wrong while merging this merge request. Please try again.'); // eslint-disable-line
        });
    },
    initiateRemoveSourceBranchPolling() {
      // We need to show source branch is being removed spinner in another component
      eventHub.$emit('SetBranchRemoveFlag', [true]);

      simplePoll((continuePolling, stopPolling) => {
        this.handleRemoveBranchPolling(continuePolling, stopPolling);
      });
    },
    handleRemoveBranchPolling(continuePolling, stopPolling) {
      this.service.poll()
        .then(res => res.data)
        .then((data) => {
          // If source branch exists then we should continue polling
          // because removing a source branch is a background task and takes time
          if (data.source_branch_exists) {
            continuePolling();
          } else {
            // Branch is removed. Update widget, stop polling and hide the spinner
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              eventHub.$emit('SetBranchRemoveFlag', [false]);
            });
            stopPolling();
          }
        })
        .catch(() => {
          new Flash('Something went wrong while removing the source branch. Please try again.'); // eslint-disable-line
        });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon :status="iconClass" />
      <div class="media-body">
        <div class="mr-widget-body-controls media space-children">
          <span class="btn-group append-bottom-5">
            <button
              @click="handleMergeButtonClick()"
              :disabled="isMergeButtonDisabled"
              :class="mergeButtonClass"
              type="button"
              class="qa-merge-button">
              <i
                v-if="isMakingRequest"
                class="fa fa-spinner fa-spin"
                aria-hidden="true" />
              {{mergeButtonText}}
            </button>
            <button
              v-if="shouldShowMergeOptionsDropdown"
              :disabled="isMergeButtonDisabled"
              type="button"
              class="btn btn-sm btn-info dropdown-toggle js-merge-moment"
              data-toggle="dropdown"
              aria-label="Select merge moment">
              <i
                class="fa fa-chevron-down"
                aria-hidden="true" />
            </button>
            <ul
              v-if="shouldShowMergeOptionsDropdown"
              class="dropdown-menu dropdown-menu-right"
              role="menu">
              <li>
                <a
                  @click.prevent="handleMergeButtonClick(true)"
                  class="merge_when_pipeline_succeeds"
                  href="#">
                  <span class="media">
                    <span
                      v-html="successSvg"
                      class="merge-opt-icon"
                      aria-hidden="true"></span>
                    <span class="media-body merge-opt-title">Merge when pipeline succeeds</span>
                  </span>
                </a>
              </li>
              <li>
                <a
                  @click.prevent="handleMergeButtonClick(false, true)"
                  class="accept-merge-request"
                  href="#">
                  <span class="media">
                    <span
                      v-html="warningSvg"
                      class="merge-opt-icon"
                      aria-hidden="true"></span>
                    <span class="media-body merge-opt-title">Merge immediately</span>
                  </span>
                </a>
              </li>
            </ul>
          </span>
          <div class="media-body-wrap space-children">
            <template v-if="shouldShowMergeControls()">
              <label v-if="mr.canRemoveSourceBranch">
                <input
                  id="remove-source-branch-input"
                  v-model="removeSourceBranch"
                  class="js-remove-source-branch-checkbox"
                  :disabled="isRemoveSourceBranchButtonDisabled"
                  type="checkbox"/> Remove source branch
              </label>

              <!-- Placeholder for EE extension of this component -->
              <squash-before-merge
                v-if="shouldShowSquashBeforeMerge"
                :mr="mr"
                :is-merge-button-disabled="isMergeButtonDisabled" />

              <span
                v-if="mr.ffOnlyEnabled"
                class="js-fast-forward-message">
                Fast-forward merge without a merge commit
              </span>
              <button
                v-else
                @click="toggleCommitMessageEditor"
                :disabled="isMergeButtonDisabled"
                class="js-modify-commit-message-button btn btn-default btn-sm"
                type="button">
                Modify commit message
              </button>
            </template>
            <template v-else>
              <span class="bold js-resolve-mr-widget-items-message">
                You can only merge once the items above are resolved
              </span>
            </template>
          </div>
        </div>
        <div
          v-if="showCommitMessageEditor"
          class="prepend-top-default commit-message-editor">
          <div class="form-group clearfix">
            <label
              class="col-form-label"
              for="commit-message">
              Commit message
            </label>
            <div class="col-sm-10">
              <div class="commit-message-container">
                <div class="max-width-marker"></div>
                <textarea
                  v-model="commitMessage"
                  class="form-control js-commit-message"
                  required="required"
                  rows="14"
                  name="Commit message"></textarea>
              </div>
              <p class="hint">Try to keep the first line under 52 characters and the others under 72</p>
              <div class="hint">
                <a
                  @click.prevent="updateCommitMessage"
                  href="#">{{commitMessageLinkTitle}}</a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
};
