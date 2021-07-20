<script>
import {
  GlIcon,
  GlButton,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlSprintf,
  GlLink,
  GlTooltipDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import readyToMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/ready_to_merge';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import createFlash from '~/flash';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import simplePoll from '~/lib/utils/simple_poll';
import { __ } from '~/locale';
import SmartInterval from '~/smart_interval';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MergeRequest from '../../../merge_request';
import {
  AUTO_MERGE_STRATEGIES,
  DANGER,
  CONFIRM,
  WARNING,
  MT_MERGE_STRATEGY,
} from '../../constants';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import MergeRequestStore from '../../stores/mr_widget_store';
import statusIcon from '../mr_widget_status_icon.vue';
import CommitEdit from './commit_edit.vue';
import CommitMessageDropdown from './commit_message_dropdown.vue';
import CommitsHeader from './commits_header.vue';
import SquashBeforeMerge from './squash_before_merge.vue';

const PIPELINE_RUNNING_STATE = 'running';
const PIPELINE_FAILED_STATE = 'failed';
const PIPELINE_PENDING_STATE = 'pending';
const PIPELINE_SUCCESS_STATE = 'success';

const MERGE_FAILED_STATUS = 'failed';
const MERGE_SUCCESS_STATUS = 'success';
const MERGE_HOOK_VALIDATION_ERROR_STATUS = 'hook_validation_error';

export default {
  name: 'ReadyToMerge',
  apollo: {
    state: {
      query: readyToMergeQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      manual: true,
      result({ data }) {
        if (Object.keys(this.state).length === 0) {
          this.removeSourceBranch =
            data.project.mergeRequest.shouldRemoveSourceBranch ||
            data.project.mergeRequest.forceRemoveSourceBranch ||
            false;
          this.commitMessage = data.project.mergeRequest.defaultMergeCommitMessage;
          this.squashBeforeMerge = data.project.mergeRequest.squashOnMerge;
          this.isSquashReadOnly = data.project.squashReadOnly;
          this.squashCommitMessage = data.project.mergeRequest.defaultSquashCommitMessage;
        }

        this.state = {
          ...data.project.mergeRequest,
          mergeRequestsFfOnlyEnabled: data.project.mergeRequestsFfOnlyEnabled,
          onlyAllowMergeIfPipelineSucceeds: data.project.onlyAllowMergeIfPipelineSucceeds,
        };
        this.loading = false;

        if (this.state.mergeTrainsCount !== null && this.state.mergeTrainsCount !== undefined) {
          this.initPolling();
        }
      },
    },
  },
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
    GlFormCheckbox,
    GlSkeletonLoader,
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
  mixins: [readyToMergeMixin, glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      loading: this.glFeatures.mergeRequestWidgetGraphql,
      state: {},
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
    stateData() {
      return this.glFeatures.mergeRequestWidgetGraphql ? this.state : this.mr;
    },
    hasCI() {
      return this.stateData.hasCI || this.stateData.hasCi;
    },
    isAutoMergeAvailable() {
      return !isEmpty(this.stateData.availableAutoMergeStrategies);
    },
    pipeline() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.headPipeline;
      }

      return this.mr.pipeline;
    },
    isPipelineFailed() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return ['FAILED', 'CANCELED'].indexOf(this.pipeline?.status) !== -1;
      }

      return this.mr.isPipelineFailed;
    },
    isMergeAllowed() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.mergeable || false;
      }

      return this.mr.isMergeAllowed;
    },
    canRemoveSourceBranch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.userPermissions.removeSourceBranch;
      }

      return this.mr.canRemoveSourceBranch;
    },
    commits() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.commitsWithoutMergeCommits.nodes;
      }

      return this.mr.commits;
    },
    commitsCount() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.commitCount || 0;
      }

      return this.mr.commitsCount;
    },
    preferredAutoMergeStrategy() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return MergeRequestStore.getPreferredAutoMergeStrategy(
          this.state.availableAutoMergeStrategies,
        );
      }

      return this.mr.preferredAutoMergeStrategy;
    },
    isSHAMismatch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.mr.sha !== this.state.diffHeadSha;
      }

      return this.mr.isSHAMismatch;
    },
    squashIsSelected() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.isSquashReadOnly ? this.state.squashOnMerge : this.state.squash;
      }

      return this.mr.squashIsSelected;
    },
    isPipelineActive() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.pipeline?.active || false;
      }

      return this.mr.isPipelineActive;
    },
    status() {
      const ciStatus = this.glFeatures.mergeRequestWidgetGraphql
        ? this.pipeline?.status.toLowerCase()
        : this.mr.ciStatus;

      if ((this.hasCI && !ciStatus) || this.hasPipelineMustSucceedConflict) {
        return PIPELINE_FAILED_STATE;
      }

      if (this.isAutoMergeAvailable) {
        return PIPELINE_PENDING_STATE;
      }

      if (this.pipeline && this.isPipelineFailed) {
        return PIPELINE_FAILED_STATE;
      }

      return PIPELINE_SUCCESS_STATE;
    },
    mergeButtonVariant() {
      if (this.status === PIPELINE_FAILED_STATE || this.isPipelineFailed) {
        return DANGER;
      }

      return CONFIRM;
    },
    iconClass() {
      if (this.shouldRenderMergeTrainHelperText && !this.mr.preventMerge) {
        return PIPELINE_RUNNING_STATE;
      }

      if (
        this.status === PIPELINE_FAILED_STATE ||
        !this.commitMessage.length ||
        !this.isMergeAllowed ||
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
      return !this.hasCI && this.stateData.onlyAllowMergeIfPipelineSucceeds;
    },
    isRemoveSourceBranchButtonDisabled() {
      return this.isMergeButtonDisabled;
    },
    shouldShowSquashBeforeMerge() {
      const { enableSquashBeforeMerge } = this.mr;

      if (this.isSquashReadOnly && !this.squashIsSelected) {
        return false;
      }

      return enableSquashBeforeMerge && this.commitsCount > 1;
    },
    shouldShowMergeControls() {
      return this.isMergeAllowed || this.isAutoMergeAvailable;
    },
    shouldShowSquashEdit() {
      return this.squashBeforeMerge && this.shouldShowSquashBeforeMerge;
    },
    shouldShowMergeEdit() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return !this.state.mergeRequestsFfOnlyEnabled;
      }

      return !this.mr.ffOnlyEnabled;
    },
    shaMismatchLink() {
      return this.mr.mergeRequestDiffsPath;
    },
    showDangerMessageForMergeTrain() {
      return this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY && this.isPipelineFailed;
    },
  },
  mounted() {
    if (this.glFeatures.mergeRequestWidgetGraphql) {
      eventHub.$on('ApprovalUpdated', this.updateGraphqlState);
    }
  },
  beforeDestroy() {
    if (this.glFeatures.mergeRequestWidgetGraphql) {
      eventHub.$off('ApprovalUpdated', this.updateGraphqlState);
    }

    if (this.pollingInterval) {
      this.pollingInterval.destroy();
    }
  },
  methods: {
    initPolling() {
      const startingPollInterval = secondsToMilliseconds(5);

      this.pollingInterval = new SmartInterval({
        callback: () => this.$apollo.queries.state.refetch(),
        startingInterval: startingPollInterval,
        maxInterval: startingPollInterval + secondsToMilliseconds(4 * 60),
        hiddenInterval: secondsToMilliseconds(6 * 60),
        incrementByFactorOf: 2,
      });
    },
    updateGraphqlState() {
      return this.$apollo.queries.state.refetch();
    },
    updateMergeCommitMessage(includeDescription) {
      const commitMessage = this.glFeatures.mergeRequestWidgetGraphql
        ? this.state.defaultMergeCommitMessage
        : this.mr.commitMessage;
      const commitMessageWithDescription = this.glFeatures.mergeRequestWidgetGraphql
        ? this.state.defaultMergeCommitMessageWithDescription
        : this.mr.commitMessageWithDescription;
      this.commitMessage = includeDescription ? commitMessageWithDescription : commitMessage;
    },
    handleMergeButtonClick(useAutoMerge, mergeImmediately = false) {
      if (mergeImmediately) {
        this.isMergingImmediately = true;
      }
      const latestSha = this.glFeatures.mergeRequestWidgetGraphql
        ? this.state.diffHeadSha
        : this.mr.latestSHA;

      const options = {
        sha: latestSha || this.mr.sha,
        commit_message: this.commitMessage,
        auto_merge_strategy: useAutoMerge ? this.preferredAutoMergeStrategy : undefined,
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
        .then((res) => res.data)
        .then((data) => {
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

          if (this.glFeatures.mergeRequestWidgetGraphql) {
            this.updateGraphqlState();
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
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
        .then((res) => res.data)
        .then((data) => {
          if (data.state === 'merged') {
            // If state is merged we should update the widget and stop the polling
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('FetchActionsContent');
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
          createFlash({
            message: __('Something went wrong while merging this merge request. Please try again.'),
          });
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
        .then((res) => res.data)
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
          createFlash({
            message: __('Something went wrong while deleting the source branch. Please try again.'),
          });
        });
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="mr-widget-body">
      <div class="gl-w-full mr-ready-to-merge-loader">
        <gl-skeleton-loader :width="418" :height="30">
          <rect x="0" y="3" width="24" height="24" rx="4" />
          <rect x="32" y="0" width="70" height="30" rx="4" />
          <rect x="110" y="7" width="150" height="16" rx="4" />
          <rect x="268" y="7" width="150" height="16" rx="4" />
        </gl-skeleton-loader>
      </div>
    </div>
    <template v-else>
      <div class="mr-widget-body media" :class="{ 'gl-pb-3': shouldRenderMergeTrainHelperText }">
        <status-icon :status="iconClass" />
        <div class="media-body">
          <div class="mr-widget-body-controls gl-display-flex gl-align-items-center">
            <gl-button-group class="gl-align-self-start">
              <gl-button
                size="medium"
                category="primary"
                class="accept-merge-request"
                data-testid="merge-button"
                :variant="mergeButtonVariant"
                :disabled="isMergeButtonDisabled"
                :loading="isMakingRequest"
                data-qa-selector="merge_button"
                @click="handleMergeButtonClick(isAutoMergeAvailable)"
                >{{ mergeButtonText }}</gl-button
              >
              <gl-dropdown
                v-if="shouldShowMergeImmediatelyDropdown"
                v-gl-tooltip.hover.focus="__('Select merge moment')"
                :disabled="isMergeButtonDisabled"
                :variant="mergeButtonVariant"
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
                  data-qa-selector="merge_immediately_menu_item"
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
            <div
              v-if="shouldShowMergeControls"
              class="gl-display-flex gl-align-items-center gl-flex-wrap"
            >
              <gl-form-checkbox
                v-if="canRemoveSourceBranch"
                id="remove-source-branch-input"
                v-model="removeSourceBranch"
                :disabled="isRemoveSourceBranchButtonDisabled"
                class="js-remove-source-branch-checkbox gl-mx-3 gl-display-flex gl-align-items-center"
              >
                {{ __('Delete source branch') }}
              </gl-form-checkbox>

              <!-- Placeholder for EE extension of this component -->
              <squash-before-merge
                v-if="shouldShowSquashBeforeMerge"
                v-model="squashBeforeMerge"
                :help-path="mr.squashBeforeMergeHelpPath"
                :is-disabled="isSquashReadOnly"
                class="gl-mx-3"
              />
            </div>
            <template v-else>
              <div class="bold js-resolve-mr-widget-items-message gl-ml-3">
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
          <div v-if="isSHAMismatch" class="d-flex align-items-center mt-2 js-sha-mismatch">
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

          <div
            v-if="showDangerMessageForMergeTrain"
            class="gl-mt-5 gl-text-gray-500"
            data-testid="failed-pipeline-merge-train-text"
          >
            {{ __('The latest pipeline for this merge request did not complete successfully.') }}
          </div>
        </div>
      </div>
      <merge-train-helper-text
        v-if="shouldRenderMergeTrainHelperText"
        :pipeline-id="pipelineId"
        :pipeline-link="pipeline.path"
        :merge-train-length="stateData.mergeTrainsCount"
        :merge-train-when-pipeline-succeeds-docs-path="mr.mergeTrainWhenPipelineSucceedsDocsPath"
      />
      <template v-if="shouldShowMergeControls">
        <div
          v-if="!shouldShowMergeEdit"
          class="mr-fast-forward-message"
          data-qa-selector="fast_forward_message_content"
        >
          {{ __('Fast-forward merge without a merge commit') }}
        </div>
        <commits-header
          v-if="shouldShowSquashEdit || shouldShowMergeEdit"
          :is-squash-enabled="squashBeforeMerge"
          :commits-count="commitsCount"
          :target-branch="stateData.targetBranch"
          :is-fast-forward-enabled="!shouldShowMergeEdit"
          :class="{ 'border-bottom': stateData.mergeError }"
        >
          <ul class="border-top content-list commits-list flex-list">
            <commit-edit
              v-if="shouldShowSquashEdit"
              v-model="squashCommitMessage"
              :label="__('Squash commit message')"
              input-id="squash-message-edit"
              squash
            >
              <template #header>
                <commit-message-dropdown v-model="squashCommitMessage" :commits="commits" />
              </template>
            </commit-edit>
            <commit-edit
              v-if="shouldShowMergeEdit"
              v-model="commitMessage"
              :label="__('Merge commit message')"
              input-id="merge-message-edit"
            >
              <template #checkbox>
                <label>
                  <input
                    id="include-description"
                    type="checkbox"
                    @change="updateMergeCommitMessage($event.target.checked)"
                  />
                  {{ __('Include merge request description') }}
                </label>
              </template>
            </commit-edit>
          </ul>
        </commits-header>
      </template>
    </template>
  </div>
</template>
