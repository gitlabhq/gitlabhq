<script>
import { isEmpty } from 'lodash';
import {
  GlIcon,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlSprintf,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import readyToMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/ready_to_merge';
import simplePoll from '~/lib/utils/simple_poll';
import { __ } from '~/locale';
import MergeRequest from '../../../merge_request';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import { deprecatedCreateFlash as Flash } from '../../../flash';
import statusIcon from '../mr_widget_status_icon.vue';
import eventHub from '../../event_hub';
import SquashBeforeMerge from './squash_before_merge.vue';
import CommitsHeader from './commits_header.vue';
import CommitEdit from './commit_edit.vue';
import CommitMessageDropdown from './commit_message_dropdown.vue';
import { AUTO_MERGE_STRATEGIES, DANGER, INFO, WARNING } from '../../constants';

const PIPELINE_RUNNING_STATE = 'running';
const PIPELINE_FAILED_STATE = 'failed';
const PIPELINE_PENDING_STATE = 'pending';
const PIPELINE_SUCCESS_STATE = 'success';

const MERGE_FAILED_STATUS = 'failed';
const MERGE_SUCCESS_STATUS = 'success';
const MERGE_HOOK_VALIDATION_ERROR_STATUS = 'hook_validation_error';

export default {
  name: 'ReadyToMerge',
  components: {
    statusIcon,
    SquashBeforeMerge,
    CommitsHeader,
    CommitEdit,
    CommitMessageDropdown,
    GlIcon,
    GlSprintf,
    GlLink,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    MergeTrainHelperText: () =>
      import('ee_component/vue_merge_request_widget/components/merge_train_helper_text.vue'),
    MergeImmediatelyConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
      squashBeforeMerge: this.mr.squashIsSelected,
      isSquashReadOnly: this.mr.squashIsReadonly,
      squashCommitMessage: this.mr.squashCommitMessage,
    };
  },
  computed: {
    isAutoMergeAvailable() {
      return !isEmpty(this.mr.availableAutoMergeStrategies);
    },
    status() {
      const { pipeline, isPipelineFailed, hasCI, ciStatus } = this.mr;

      if ((hasCI && !ciStatus) || this.hasPipelineMustSucceedConflict) {
        return PIPELINE_FAILED_STATE;
      }

      if (this.isAutoMergeAvailable) {
        return PIPELINE_PENDING_STATE;
      }

      if (pipeline && isPipelineFailed) {
        return PIPELINE_FAILED_STATE;
      }

      return PIPELINE_SUCCESS_STATE;
    },
    mergeButtonVariant() {
      if (this.status === PIPELINE_FAILED_STATE) {
        return DANGER;
      }

      if (this.status === PIPELINE_PENDING_STATE) {
        return INFO;
      }

      return PIPELINE_SUCCESS_STATE;
    },
    iconClass() {
      if (this.shouldRenderMergeTrainHelperText && !this.mr.preventMerge) {
        return PIPELINE_RUNNING_STATE;
      }

      if (
        this.status === PIPELINE_FAILED_STATE ||
        !this.commitMessage.length ||
        !this.mr.isMergeAllowed ||
        this.mr.preventMerge
      ) {
        return WARNING;
      }

      return PIPELINE_SUCCESS_STATE;
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
    hasPipelineMustSucceedConflict() {
      return !this.mr.hasCI && this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    isRemoveSourceBranchButtonDisabled() {
      return this.isMergeButtonDisabled;
    },
    shouldShowSquashBeforeMerge() {
      const { commitsCount, enableSquashBeforeMerge, squashIsReadonly, squashIsSelected } = this.mr;

      if (squashIsReadonly && !squashIsSelected) {
        return false;
      }

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
      return this.mr.mergeRequestDiffsPath;
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
      };

      // If users can't alter the squash message (e.g. for 1-commit merge requests),
      // we shouldn't send the commit message because that would make the backend
      // do unnecessary work.
      if (this.shouldShowSquashBeforeMerge) {
        options.squash_commit_message = this.squashCommitMessage;
      }

      this.isMakingRequest = true;
      this.service
        .merge(options)
        .then(res => res.data)
        .then(data => {
          const hasError =
            data.status === MERGE_FAILED_STATUS ||
            data.status === MERGE_HOOK_VALIDATION_ERROR_STATUS;

          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else if (data.status === MERGE_SUCCESS_STATUS) {
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
    <div class="mr-widget-body media" :class="{ 'gl-pb-3': shouldRenderMergeTrainHelperText }">
      <status-icon :status="iconClass" />
      <div class="media-body">
        <div class="mr-widget-body-controls media space-children">
          <gl-button-group>
            <gl-button
              size="medium"
              category="primary"
              class="qa-merge-button accept-merge-request"
              :variant="mergeButtonVariant"
              :disabled="isMergeButtonDisabled"
              :loading="isMakingRequest"
              @click="handleMergeButtonClick(isAutoMergeAvailable)"
              >{{ mergeButtonText }}</gl-button
            >
            <gl-dropdown
              v-if="shouldShowMergeImmediatelyDropdown"
              v-gl-tooltip.hover.focus="__('Select merge moment')"
              :disabled="isMergeButtonDisabled"
              variant="info"
              data-qa-selector="merge_moment_dropdown"
              toggle-class="btn-icon js-merge-moment"
            >
              <template #button-content>
                <gl-icon name="chevron-down" class="mr-0" />
                <span class="sr-only">{{ __('Select merge moment') }}</span>
              </template>
              <gl-dropdown-item
                icon-name="warning"
                button-class="accept-merge-request js-merge-immediately-button"
                data-qa-selector="merge_immediately_option"
                @click="handleMergeImmediatelyButtonClick"
              >
                {{ __('Merge immediately') }}
              </gl-dropdown-item>
              <merge-immediately-confirmation-dialog
                ref="confirmationDialog"
                :docs-url="mr.mergeImmediatelyDocsPath"
                @mergeImmediately="onMergeImmediatelyConfirmation"
              />
            </gl-dropdown>
          </gl-button-group>
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
                :is-disabled="isSquashReadOnly"
              />
            </template>
            <template v-else>
              <div class="bold js-resolve-mr-widget-items-message">
                <div
                  v-if="hasPipelineMustSucceedConflict"
                  class="gl-display-flex gl-align-items-center"
                  data-testid="pipeline-succeed-conflict"
                >
                  <gl-sprintf :message="pipelineMustSucceedConflictText" />
                  <gl-link
                    :href="mr.pipelineMustSucceedDocsPath"
                    target="_blank"
                    class="gl-display-flex gl-ml-2"
                  >
                    <gl-icon name="question" />
                  </gl-link>
                </div>
                <gl-sprintf v-else :message="mergeDisabledText" />
              </div>
            </template>
          </div>
        </div>
        <div v-if="mr.isSHAMismatch" class="d-flex align-items-center mt-2 js-sha-mismatch">
          <gl-icon name="warning-solid" class="text-warning mr-1" />
          <span class="text-warning">
            <gl-sprintf
              :message="
                __('New changes were added. %{linkStart}Reload the page to review them%{linkEnd}')
              "
            >
              <template #link="{ content }">
                <gl-link :href="mr.mergeRequestDiffsPath">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </div>
      </div>
    </div>
    <merge-train-helper-text
      v-if="shouldRenderMergeTrainHelperText"
      :pipeline-id="mr.pipeline.id"
      :pipeline-link="mr.pipeline.path"
      :merge-train-length="mr.mergeTrainsCount"
      :merge-train-when-pipeline-succeeds-docs-path="mr.mergeTrainWhenPipelineSucceedsDocsPath"
    />
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
