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
import createFlash from '~/flash';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import simplePoll from '~/lib/utils/simple_poll';
import { __, s__ } from '~/locale';
import SmartInterval from '~/smart_interval';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  AUTO_MERGE_STRATEGIES,
  WARNING,
  MT_MERGE_STRATEGY,
  PIPELINE_FAILED_STATE,
  STATE_MACHINE,
} from '../../constants';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import MergeRequestStore from '../../stores/mr_widget_store';
import AddedCommitMessage from '../added_commit_message.vue';
import RelatedLinks from '../mr_widget_related_links.vue';
import CommitEdit from './commit_edit.vue';
import CommitMessageDropdown from './commit_message_dropdown.vue';
import SquashBeforeMerge from './squash_before_merge.vue';
import MergeFailedPipelineConfirmationDialog from './merge_failed_pipeline_confirmation_dialog.vue';

const PIPELINE_RUNNING_STATE = 'running';
const PIPELINE_PENDING_STATE = 'pending';
const PIPELINE_SUCCESS_STATE = 'success';

const MERGE_FAILED_STATUS = 'failed';
const MERGE_SUCCESS_STATUS = 'success';
const MERGE_HOOK_VALIDATION_ERROR_STATUS = 'hook_validation_error';

const { transitions } = STATE_MACHINE;
const { MERGE, MERGE_FAILURE, AUTO_MERGE, MERGING } = transitions;

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

        if (!this.commitMessageIsTouched) {
          this.commitMessage = this.state.defaultMergeCommitMessage;
        }
        if (!this.squashCommitMessageIsTouched) {
          this.squashCommitMessage = this.state.defaultSquashCommitMessage;
        }

        if (this.state.mergeTrainsCount !== null && this.state.mergeTrainsCount !== undefined) {
          this.initPolling();
        }
      },
    },
  },
  components: {
    SquashBeforeMerge,
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
    MergeFailedPipelineConfirmationDialog,
    MergeTrainHelperIcon: () =>
      import('ee_component/vue_merge_request_widget/components/merge_train_helper_icon.vue'),
    MergeImmediatelyConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue'
      ),
    MergeTrainFailedPipelineConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_train_failed_pipeline_confirmation_dialog.vue'
      ),
    AddedCommitMessage,
    RelatedLinks,
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
      commitMessageIsTouched: false,
      squashBeforeMerge: this.mr.squashIsSelected,
      isSquashReadOnly: this.mr.squashIsReadonly,
      squashCommitMessage: this.mr.squashCommitMessage,
      squashCommitMessageIsTouched: false,
      isPipelineFailedModalVisibleMergeTrain: false,
      isPipelineFailedModalVisibleNormalMerge: false,
      editCommitMessage: false,
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
    showMergeFailedPipelineConfirmationDialog() {
      return this.status === PIPELINE_FAILED_STATE && this.isPipelineFailed;
    },
    isMergeAllowed() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.mergeable;
      }

      return this.mr.isMergeAllowed;
    },
    canRemoveSourceBranch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.userPermissions.removeSourceBranch;
      }

      return this.mr.canRemoveSourceBranch;
    },
    commitTemplateHelpPage() {
      return helpPagePath('user/project/merge_requests/commit_templates.md');
    },
    commitTemplateHintText() {
      if (this.shouldShowSquashEdit && this.shouldShowMergeEdit) {
        return this.$options.i18n.mergeAndSquashCommitTemplatesHintText;
      }
      if (this.shouldShowSquashEdit) {
        return this.$options.i18n.squashCommitTemplateHintText;
      }
      return this.$options.i18n.mergeCommitTemplateHintText;
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
    iconClass() {
      if (this.shouldRenderMergeTrainHelperIcon && !this.mr.preventMerge) {
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

      if (this.status === PIPELINE_FAILED_STATE || this.isPipelineFailed) {
        return __('Merge...');
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

      return enableSquashBeforeMerge;
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
    shouldShowMergeControls() {
      return (
        (this.isMergeAllowed || this.isAutoMergeAvailable) &&
        (this.stateData.userPermissions?.canMerge || this.mr.canMerge) &&
        !this.mr.mergeOngoing &&
        !this.mr.autoMergeEnabled
      );
    },
    sourceBranchDeletedText() {
      if (this.removeSourceBranch) {
        return this.mr.state === 'merged'
          ? __('Deleted the source branch.')
          : __('Source branch will be deleted.');
      }

      return this.mr.state === 'merged'
        ? __('Did not delete the source branch.')
        : __('Source branch will not be deleted.');
    },
    showMergeDetailsHeader() {
      return ['readyToMerge'].indexOf(this.mr.state) >= 0;
    },
  },
  mounted() {
    if (this.glFeatures.mergeRequestWidgetGraphql) {
      eventHub.$on('ApprovalUpdated', this.updateGraphqlState);
      eventHub.$on('MRWidgetUpdateRequested', this.updateGraphqlState);
      eventHub.$on('mr.discussion.updated', this.updateGraphqlState);
    }
  },
  beforeDestroy() {
    if (this.glFeatures.mergeRequestWidgetGraphql) {
      eventHub.$off('ApprovalUpdated', this.updateGraphqlState);
      eventHub.$off('MRWidgetUpdateRequested', this.updateGraphqlState);
      eventHub.$off('mr.discussion.updated', this.updateGraphqlState);
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
    handleMergeButtonClick(useAutoMerge, mergeImmediately = false, confirmationClicked = false) {
      if (this.showMergeFailedPipelineConfirmationDialog && !confirmationClicked) {
        this.isPipelineFailedModalVisibleNormalMerge = true;
        return;
      }

      if (this.showFailedPipelineModalMergeTrain && !confirmationClicked) {
        this.isPipelineFailedModalVisibleMergeTrain = true;
        return;
      }

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
      this.editCommitMessage = false;

      if (!useAutoMerge) {
        this.mr.transitionStateMachine({ transition: MERGE });
      }

      this.service
        .merge(options)
        .then((res) => res.data)
        .then((data) => {
          const hasError =
            data.status === MERGE_FAILED_STATUS ||
            data.status === MERGE_HOOK_VALIDATION_ERROR_STATUS;

          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
            this.mr.transitionStateMachine({ transition: AUTO_MERGE });
          } else if (data.status === MERGE_SUCCESS_STATUS) {
            this.mr.transitionStateMachine({ transition: MERGING });
          } else if (hasError) {
            eventHub.$emit('FailedToMerge', data.merge_error);
            this.mr.transitionStateMachine({ transition: MERGE_FAILURE });
          }

          if (this.glFeatures.mergeRequestWidgetGraphql) {
            this.updateGraphqlState();
          }

          this.isMakingRequest = false;
        })
        .catch(() => {
          this.isMakingRequest = false;
          this.mr.transitionStateMachine({ transition: MERGE_FAILURE });
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
      this.handleMergeButtonClick(false, true, true);
    },
    onMergeWithFailedPipelineConfirmation() {
      this.handleMergeButtonClick(false, true, true);
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
    setCommitMessage(val) {
      this.commitMessage = val;
      this.commitMessageIsTouched = true;
    },
    setSquashCommitMessage(val) {
      this.squashCommitMessage = val;
      this.squashCommitMessageIsTouched = true;
    },
  },
  i18n: {
    mergeCommitTemplateHintText: s__(
      'mrWidget|To change this default message, edit the template for merge commit messages. %{linkStart}Learn more.%{linkEnd}',
    ),
    squashCommitTemplateHintText: s__(
      'mrWidget|To change this default message, edit the template for squash commit messages. %{linkStart}Learn more.%{linkEnd}',
    ),
    mergeAndSquashCommitTemplatesHintText: s__(
      'mrWidget|To change these default messages, edit the templates for both the merge and squash commit messages. %{linkStart}Learn more.%{linkEnd}',
    ),
  },
};
</script>

<template>
  <div
    data-testid="ready_to_merge_state"
    class="gl-border-t-1 gl-border-t-solid gl-border-gray-100 gl-bg-gray-10 gl-pl-7 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
  >
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
      <div class="mr-widget-body mr-widget-body-ready-merge media mr-widget-body-line-height-1">
        <div class="media-body">
          <div class="mr-widget-body-controls gl-display-flex gl-align-items-center gl-flex-wrap">
            <gl-button-group v-if="shouldShowMergeControls" class="gl-align-self-start">
              <gl-button
                size="medium"
                category="primary"
                class="accept-merge-request"
                data-testid="merge-button"
                variant="confirm"
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
                variant="confirm"
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
              <merge-train-failed-pipeline-confirmation-dialog
                :visible="isPipelineFailedModalVisibleMergeTrain"
                @startMergeTrain="onStartMergeTrainConfirmation"
                @cancel="isPipelineFailedModalVisibleMergeTrain = false"
              />
              <merge-failed-pipeline-confirmation-dialog
                :visible="isPipelineFailedModalVisibleNormalMerge"
                @mergeWithFailedPipeline="onMergeWithFailedPipelineConfirmation"
                @cancel="isPipelineFailedModalVisibleNormalMerge = false"
              />
            </gl-button-group>
            <merge-train-helper-icon v-if="shouldRenderMergeTrainHelperIcon" class="gl-mx-3" />
            <div
              v-if="shouldShowMergeControls"
              class="gl-display-flex gl-align-items-center gl-flex-wrap gl-w-full gl-order-n1 gl-mb-5"
            >
              <gl-form-checkbox
                v-if="canRemoveSourceBranch"
                id="remove-source-branch-input"
                v-model="removeSourceBranch"
                :disabled="isRemoveSourceBranchButtonDisabled"
                class="js-remove-source-branch-checkbox gl-display-flex gl-align-items-center gl-mr-5"
              >
                {{ __('Delete source branch') }}
              </gl-form-checkbox>

              <!-- Placeholder for EE extension of this component -->
              <squash-before-merge
                v-if="shouldShowSquashBeforeMerge"
                v-model="squashBeforeMerge"
                :help-path="mr.squashBeforeMergeHelpPath"
                :is-disabled="isSquashReadOnly"
                class="gl-mr-5"
              />

              <gl-form-checkbox
                v-if="shouldShowSquashEdit || shouldShowMergeEdit"
                v-model="editCommitMessage"
                data-testid="widget_edit_commit_message"
                class="gl-display-flex gl-align-items-center"
              >
                {{ __('Edit commit message') }}
              </gl-form-checkbox>
            </div>
            <div
              v-if="editCommitMessage"
              class="gl-w-full gl-order-n1"
              data-testid="edit_commit_message"
            >
              <ul class="border-top commits-list flex-list gl-list-style-none gl-p-0 gl-pt-4">
                <commit-edit
                  v-if="shouldShowSquashEdit"
                  :value="squashCommitMessage"
                  :label="__('Squash commit message')"
                  input-id="squash-message-edit"
                  class="gl-m-0! gl-p-0!"
                  @input="setSquashCommitMessage"
                >
                  <template #header>
                    <commit-message-dropdown :commits="commits" @input="setSquashCommitMessage" />
                  </template>
                </commit-edit>
                <commit-edit
                  v-if="shouldShowMergeEdit"
                  :value="commitMessage"
                  :label="__('Merge commit message')"
                  input-id="merge-message-edit"
                  class="gl-m-0! gl-p-0!"
                  @input="setCommitMessage"
                />
                <li class="gl-m-0! gl-p-0!">
                  <p class="form-text text-muted">
                    <gl-sprintf :message="commitTemplateHintText">
                      <template #link="{ content }">
                        <gl-link :href="commitTemplateHelpPage" class="inline-link" target="_blank">
                          {{ content }}
                        </gl-link>
                      </template>
                    </gl-sprintf>
                  </p>
                </li>
              </ul>
            </div>
            <div
              v-if="!shouldShowMergeControls"
              class="gl-w-full gl-order-n1 mr-widget-merge-details"
              data-qa-selector="merged_status_content"
            >
              <p v-if="showMergeDetailsHeader" class="gl-mb-3 gl-text-gray-900">
                {{ __('Merge details') }}
              </p>
              <ul class="gl-pl-4 gl-mb-0 gl-ml-3 gl-text-gray-600">
                <li v-if="mr.divergedCommitsCount > 0" class="gl-line-height-normal">
                  <gl-sprintf
                    :message="s__('mrWidget|The source branch is %{link} the target branch')"
                  >
                    <template #link>
                      <gl-link :href="mr.targetBranchPath">{{
                        n__('%d commit behind', '%d commits behind', mr.divergedCommitsCount)
                      }}</gl-link>
                    </template>
                  </gl-sprintf>
                </li>
                <li class="gl-line-height-normal">
                  <added-commit-message
                    :state="mr.state"
                    :merge-commit-sha="mr.shortMergeCommitSha"
                    :is-squash-enabled="squashBeforeMerge"
                    :is-fast-forward-enabled="!shouldShowMergeEdit"
                    :commits-count="commitsCount"
                    :target-branch="stateData.targetBranch"
                  />
                </li>
                <li v-if="mr.state !== 'closed'" class="gl-line-height-normal">
                  {{ sourceBranchDeletedText }}
                </li>
                <li v-if="mr.relatedLinks" class="gl-line-height-normal">
                  <related-links
                    :state="mr.state"
                    :related-links="mr.relatedLinks"
                    :show-assign-to-me="false"
                    class="mr-ready-merge-related-links gl-display-inline"
                  />
                </li>
              </ul>
            </div>
            <div
              v-else
              :class="{ 'gl-mb-5': shouldShowMergeControls }"
              class="gl-w-full gl-order-n1 gl-text-gray-500"
            >
              <added-commit-message
                :is-squash-enabled="squashBeforeMerge"
                :is-fast-forward-enabled="!shouldShowMergeEdit"
                :commits-count="commitsCount"
                :target-branch="stateData.targetBranch"
              />
              <template v-if="mr.relatedLinks">
                &middot;
                <related-links
                  :state="mr.state"
                  :related-links="mr.relatedLinks"
                  :show-assign-to-me="false"
                  :diverged-commits-count="mr.divergedCommitsCount"
                  :target-branch-path="mr.targetBranchPath"
                  class="mr-ready-merge-related-links gl-display-inline"
                />
              </template>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
