<script>
import _ from 'underscore';
import { GlIcon } from '@gitlab/ui';
import successSvg from 'icons/_icon_status_success.svg';
import warningSvg from 'icons/_icon_status_warning.svg';
import readyToMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/ready_to_merge';
import simplePoll from '~/lib/utils/simple_poll';
import { __, sprintf } from '~/locale';
import MergeRequest from '../../../merge_request';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import Flash from '../../../flash';
import statusIcon from '../mr_widget_status_icon.vue';
import eventHub from '../../event_hub';
import SquashBeforeMerge from './squash_before_merge.vue';
import CommitsHeader from './commits_header.vue';
import CommitEdit from './commit_edit.vue';
import CommitMessageDropdown from './commit_message_dropdown.vue';
import { AUTO_MERGE_STRATEGIES } from '../../constants';

export default {
  name: 'ReadyToMerge',
  components: {
    statusIcon,
    SquashBeforeMerge,
    CommitsHeader,
    CommitEdit,
    CommitMessageDropdown,
    GlIcon,
    MergeImmediatelyConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue'
      ),
  },
  mixins: [readyToMergeMixin],
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      removeSourceBranch: this.mr.shouldRemoveSourceBranch,
      isMakingRequest: false,
      isMergingImmediately: false,
      commitMessage: this.mr.commitMessage,
      squashBeforeMerge: this.mr.squash,
      successSvg,
      warningSvg,
      squashCommitMessage: this.mr.squashCommitMessage,
    };
  },
  computed: {
    isAutoMergeAvailable() {
      return !_.isEmpty(this.mr.availableAutoMergeStrategies);
    },
    status() {
      const { pipeline, isPipelineFailed, hasCI, ciStatus } = this.mr;

      if (hasCI && !ciStatus) {
        return 'failed';
      } else if (this.isAutoMergeAvailable) {
        return 'pending';
      } else if (!pipeline) {
        return 'success';
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
      if (
        this.status === 'failed' ||
        !this.commitMessage.length ||
        !this.mr.isMergeAllowed ||
        this.mr.preventMerge
      ) {
        return 'warning';
      }
      return 'success';
    },
    mergeButtonText() {
      if (this.isMergingImmediately) {
        return __('Merge in progress');
      }
      if (this.isAutoMergeAvailable) {
        return this.autoMergeText;
      }

      return __('Merge');
    },
    isRemoveSourceBranchButtonDisabled() {
      return this.isMergeButtonDisabled;
    },
    shouldShowSquashBeforeMerge() {
      const { commitsCount, enableSquashBeforeMerge } = this.mr;
      return enableSquashBeforeMerge && commitsCount > 1;
    },
    shouldShowMergeControls() {
      return this.mr.isMergeAllowed || this.isAutoMergeAvailable;
    },
    shouldShowSquashEdit() {
      return this.squashBeforeMerge && this.shouldShowSquashBeforeMerge;
    },
    shouldShowMergeEdit() {
      return !this.mr.ffOnlyEnabled;
    },
    shaMismatchLink() {
      const href = this.mr.mergeRequestDiffsPath;

      return sprintf(
        __('New changes were added. %{linkStart}Reload the page to review them%{linkEnd}'),
        {
          linkStart: `<a href="${href}">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  methods: {
    updateMergeCommitMessage(includeDescription) {
      const { commitMessageWithDescription, commitMessage } = this.mr;
      this.commitMessage = includeDescription ? commitMessageWithDescription : commitMessage;
    },
    handleMergeButtonClick(useAutoMerge, mergeImmediately = false) {
      if (mergeImmediately) {
        this.isMergingImmediately = true;
      }

      const options = {
        sha: this.mr.latestSHA || this.mr.sha,
        commit_message: this.commitMessage,
        auto_merge_strategy: useAutoMerge ? this.mr.preferredAutoMergeStrategy : undefined,
        should_remove_source_branch: this.removeSourceBranch === true,
        squash: this.squashBeforeMerge,
        squash_commit_message: this.squashCommitMessage,
      };

      this.isMakingRequest = true;
      this.service
        .merge(options)
        .then(res => res.data)
        .then(data => {
          const hasError = data.status === 'failed' || data.status === 'hook_validation_error';

          if (_.includes(AUTO_MERGE_STRATEGIES, data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else if (data.status === 'success') {
            this.initiateMergePolling();
          } else if (hasError) {
            eventHub.$emit('FailedToMerge', data.merge_error);
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          new Flash(__('Something went wrong. Please try again.')); // eslint-disable-line
        });
    },
    handleMergeImmediatelyButtonClick() {
      if (this.isMergeImmediatelyDangerous) {
        this.$refs.confirmationDialog.show();
      } else {
        this.handleMergeButtonClick(false, true);
      }
    },
    onMergeImmediatelyConfirmation() {
      this.handleMergeButtonClick(false, true);
    },
    initiateMergePolling() {
      simplePoll(
        (continuePolling, stopPolling) => {
          this.handleMergePolling(continuePolling, stopPolling);
        },
        { timeout: 0 },
      );
    },
    handleMergePolling(continuePolling, stopPolling) {
      this.service
        .poll()
        .then(res => res.data)
        .then(data => {
          if (data.state === 'merged') {
            // If state is merged we should update the widget and stop the polling
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('FetchActionsContent');
            MergeRequest.setStatusBoxToMerged();
            MergeRequest.hideCloseButton();
            MergeRequest.decreaseCounter();
            stopPolling();

            refreshUserMergeRequestCounts();

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
          new Flash(__('Something went wrong while merging this merge request. Please try again.')); // eslint-disable-line
          stopPolling();
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
      this.service
        .poll()
        .then(res => res.data)
        .then(data => {
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
          new Flash(__('Something went wrong while deleting the source branch. Please try again.')); // eslint-disable-line
        });
    },
  },
};
</script>

<template>
  <div>
    <div class="mr-widget-body media">
      <status-icon :status="iconClass" />
      <div class="media-body">
        <div class="mr-widget-body-controls media space-children">
          <span class="btn-group">
            <button
              :disabled="isMergeButtonDisabled"
              :class="mergeButtonClass"
              type="button"
              class="qa-merge-button"
              @click="handleMergeButtonClick(isAutoMergeAvailable)"
            >
              <i v-if="isMakingRequest" class="fa fa-spinner fa-spin" aria-hidden="true"></i>
              {{ mergeButtonText }}
            </button>
            <button
              v-if="shouldShowMergeImmediatelyDropdown"
              :disabled="isMergeButtonDisabled"
              type="button"
              class="btn btn-sm btn-info dropdown-toggle js-merge-moment"
              data-toggle="dropdown"
              data-qa-selector="merge_moment_dropdown"
              :aria-label="__('Select merge moment')"
            >
              <i class="fa fa-chevron-down" aria-hidden="true"></i>
            </button>
            <ul
              v-if="shouldShowMergeImmediatelyDropdown"
              class="dropdown-menu dropdown-menu-right"
              role="menu"
            >
              <li>
                <a
                  class="auto_merge_enabled qa-merge-when-pipeline-succeeds-option"
                  href="#"
                  @click.prevent="handleMergeButtonClick(true)"
                >
                  <span class="media">
                    <span class="merge-opt-icon" aria-hidden="true" v-html="successSvg"></span>
                    <span class="media-body merge-opt-title">{{ autoMergeText }}</span>
                  </span>
                </a>
              </li>
              <li>
                <merge-immediately-confirmation-dialog
                  ref="confirmationDialog"
                  :docs-url="mr.mergeImmediatelyDocsPath"
                  @mergeImmediately="onMergeImmediatelyConfirmation"
                />
                <a
                  class="accept-merge-request js-merge-immediately-button"
                  data-qa-selector="merge_immediately_option"
                  href="#"
                  @click.prevent="handleMergeImmediatelyButtonClick"
                >
                  <span class="media">
                    <span class="merge-opt-icon" aria-hidden="true" v-html="warningSvg"></span>
                    <span class="media-body merge-opt-title">{{ __('Merge immediately') }}</span>
                  </span>
                </a>
              </li>
            </ul>
          </span>
          <div class="media-body-wrap space-children">
            <template v-if="shouldShowMergeControls">
              <label v-if="mr.canRemoveSourceBranch">
                <input
                  id="remove-source-branch-input"
                  v-model="removeSourceBranch"
                  :disabled="isRemoveSourceBranchButtonDisabled"
                  class="js-remove-source-branch-checkbox"
                  type="checkbox"
                />
                {{ __('Delete source branch') }}
              </label>

              <!-- Placeholder for EE extension of this component -->
              <squash-before-merge
                v-if="shouldShowSquashBeforeMerge"
                v-model="squashBeforeMerge"
                :help-path="mr.squashBeforeMergeHelpPath"
                :is-disabled="isMergeButtonDisabled"
              />
            </template>
            <template v-else>
              <span class="bold js-resolve-mr-widget-items-message">
                {{ mergeDisabledText }}
              </span>
            </template>
          </div>
        </div>
        <div v-if="mr.isSHAMismatch" class="d-flex align-items-center mt-2 js-sha-mismatch">
          <gl-icon name="warning-solid" class="text-warning mr-1" />
          <span class="text-warning" v-html="shaMismatchLink"></span>
        </div>
      </div>
    </div>
    <template v-if="shouldShowMergeControls">
      <div v-if="mr.ffOnlyEnabled" class="mr-fast-forward-message">
        {{ __('Fast-forward merge without a merge commit') }}
      </div>
      <commits-header
        v-if="shouldShowSquashEdit || shouldShowMergeEdit"
        :is-squash-enabled="squashBeforeMerge"
        :commits-count="mr.commitsCount"
        :target-branch="mr.targetBranch"
        :is-fast-forward-enabled="mr.ffOnlyEnabled"
        :class="{ 'border-bottom': mr.mergeError }"
      >
        <ul class="border-top content-list commits-list flex-list">
          <commit-edit
            v-if="shouldShowSquashEdit"
            v-model="squashCommitMessage"
            :label="__('Squash commit message')"
            input-id="squash-message-edit"
            squash
          >
            <commit-message-dropdown
              slot="header"
              v-model="squashCommitMessage"
              :commits="mr.commits"
            />
          </commit-edit>
          <commit-edit
            v-if="shouldShowMergeEdit"
            v-model="commitMessage"
            :label="__('Merge commit message')"
            input-id="merge-message-edit"
          >
            <label slot="checkbox">
              <input
                id="include-description"
                type="checkbox"
                @change="updateMergeCommitMessage($event.target.checked)"
              />
              {{ __('Include merge request description') }}
            </label>
          </commit-edit>
        </ul>
      </commits-header>
    </template>
  </div>
</template>
