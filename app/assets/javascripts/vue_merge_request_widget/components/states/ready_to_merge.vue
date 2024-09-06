<script>
import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormCheckbox,
  GlSprintf,
  GlLink,
  GlTooltipDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { isEmpty, isNil } from 'lodash';
import readyToMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/ready_to_merge';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import simplePoll from '~/lib/utils/simple_poll';
import { __, s__, n__ } from '~/locale';
import SmartInterval from '~/smart_interval';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import readyToMergeSubscription from '~/vue_merge_request_widget/queries/states/ready_to_merge.subscription.graphql';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  AUTO_MERGE_STRATEGIES,
  MT_MERGE_STRATEGY,
  PIPELINE_FAILED_STATE,
  STATE_MACHINE,
  MT_SKIP_TRAIN,
  MT_RESTART_TRAIN,
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
      fetchPolicy: fetchPolicies.NO_CACHE,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      manual: true,
      result({ data }) {
        if (!data?.project?.mergeRequest) {
          return;
        }

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

        if (!isNil(this.state.mergeTrainsCount) && !this.pollingInterval) {
          this.initPolling();
        }
      },
      subscribeToMore: {
        document() {
          return readyToMergeSubscription;
        },
        skip() {
          return !this.mr?.id || this.loading;
        },
        variables() {
          return {
            issuableId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.mr?.id),
          };
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { mergeRequestMergeStatusUpdated },
            },
          },
        ) {
          if (mergeRequestMergeStatusUpdated) {
            this.state = {
              ...mergeRequestMergeStatusUpdated,
              mergeRequestsFfOnlyEnabled: this.state.mergeRequestsFfOnlyEnabled,
              onlyAllowMergeIfPipelineSucceeds: this.state.onlyAllowMergeIfPipelineSucceeds,
            };

            if (!this.commitMessageIsTouched) {
              this.commitMessage = mergeRequestMergeStatusUpdated.defaultMergeCommitMessage;
            }

            if (!this.squashCommitMessageIsTouched) {
              this.squashCommitMessage = mergeRequestMergeStatusUpdated.defaultSquashCommitMessage;
            }
          }
        },
      },
    },
  },
  components: {
    SquashBeforeMerge,
    CommitEdit,
    CommitMessageDropdown,
    GlSprintf,
    GlLink,
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormCheckbox,
    GlSkeletonLoader,
    MergeFailedPipelineConfirmationDialog,
    MergeImmediatelyConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_immediately_confirmation_dialog.vue'
      ),
    MergeTrainFailedPipelineConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_train_failed_pipeline_confirmation_dialog.vue'
      ),
    MergeTrainRestartTrainConfirmationDialog: () =>
      import(
        'ee_component/vue_merge_request_widget/components/merge_train_restart_train_confirmation_dialog.vue'
      ),
    AddedCommitMessage,
    RelatedLinks,
    HelpPopover,
    AiCommitMessage: () =>
      import('ee_component/vue_merge_request_widget/components/ai_commit_message.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [readyToMergeMixin, mergeRequestQueryVariablesMixin, glFeatureFlagsMixin()],
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      loading: true,
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
      isMergeTrainBeingForceMerged: false,
      mergeTrainMergeType: MT_RESTART_TRAIN,
      skipMergeTrain: false,
      mergeTrainsSkipAllowed: this.mr.mergeTrainsSkipAllowed,
      editCommitMessage: false,
    };
  },
  computed: {
    hasCI() {
      return this.state.hasCI || this.state.hasCi;
    },
    isAutoMergeAvailable() {
      return !isEmpty(this.state.availableAutoMergeStrategies);
    },
    pipeline() {
      return this.state.headPipeline;
    },
    isPipelineFailed() {
      return ['FAILED', 'CANCELED'].indexOf(this.pipeline?.status) !== -1;
    },
    showMergeFailedPipelineConfirmationDialog() {
      return (this.status === PIPELINE_FAILED_STATE && this.isPipelineFailed) || this.mr.retargeted;
    },
    isMergeAllowed() {
      return this.state.mergeable || false;
    },
    canRemoveSourceBranch() {
      return this.state.userPermissions.removeSourceBranch;
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
      return this.state.commitsWithoutMergeCommits?.nodes;
    },
    commitsCount() {
      return this.state.commitCount || 0;
    },
    preferredAutoMergeStrategy() {
      return MergeRequestStore.getPreferredAutoMergeStrategy(
        this.state.availableAutoMergeStrategies,
      );
    },
    squashIsSelected() {
      return this.isSquashReadOnly ? this.state.squashOnMerge : this.state.squash;
    },
    isPipelineActive() {
      return this.pipeline?.active || false;
    },
    status() {
      const ciStatus = this.pipeline?.status?.toLowerCase();

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
    showAutoMergeHelperText() {
      return this.isAutoMergeAvailable;
    },
    hasPipelineMustSucceedConflict() {
      return !this.hasCI && this.state.onlyAllowMergeIfPipelineSucceeds;
    },
    isNotClosed() {
      return this.mr.state !== STATUS_CLOSED;
    },
    isNeitherClosedNorMerged() {
      return this.mr.state !== STATUS_CLOSED && this.mr.state !== STATUS_MERGED;
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
      return !this.state.mergeRequestsFfOnlyEnabled;
    },
    shaMismatchLink() {
      return this.mr.mergeRequestDiffsPath;
    },
    showDangerMessageForMergeTrain() {
      return this.preferredAutoMergeStrategy === MT_MERGE_STRATEGY && this.isPipelineFailed;
    },
    shouldShowMergeControls() {
      return this.state.userPermissions?.canMerge && this.mr.state === 'readyToMerge';
    },
    sourceBranchDeletedText() {
      const isPreMerge = this.mr.state !== STATUS_MERGED;

      if (isPreMerge) {
        return this.mr.shouldRemoveSourceBranch
          ? __('Source branch will be deleted.')
          : __('Source branch will not be deleted.');
      }

      return this.mr.sourceBranchRemoved
        ? __('Deleted the source branch.')
        : __('Did not delete the source branch.');
    },
    sourceHasDivergedFromTarget() {
      return this.mr.divergedCommitsCount > 0;
    },
    showMergeDetailsHeader() {
      return !['readyToMerge'].includes(this.mr.state);
    },
    autoMergeHelpPopoverOptions() {
      return {
        title: this.autoMergePopoverSettings.title,
      };
    },
    isSkipMergeTrainAvailable() {
      return this.mergeTrainsSkipAllowed && this.glFeatures.mergeTrainsSkipTrain;
    },
    displaySkipMergeTrainOptions() {
      return this.shouldDisplayMergeImmediatelyDropdownOptions && this.isSkipMergeTrainAvailable;
    },
  },
  watch: {
    'mr.state': function mrStateWatcher() {
      this.isMakingRequest = false;
    },
  },
  mounted() {
    eventHub.$on('ApprovalUpdated', this.updateGraphqlState);
    eventHub.$on('MRWidgetUpdateRequested', this.updateGraphqlState);
    eventHub.$on('mr.discussion.updated', this.updateGraphqlState);
  },
  beforeDestroy() {
    eventHub.$off('ApprovalUpdated', this.updateGraphqlState);
    eventHub.$off('MRWidgetUpdateRequested', this.updateGraphqlState);
    eventHub.$off('mr.discussion.updated', this.updateGraphqlState);
    eventHub.$off('ApprovalUpdated', this.updateGraphqlState);

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
      if (
        this.preferredAutoMergeStrategy !== MT_MERGE_STRATEGY &&
        this.showMergeFailedPipelineConfirmationDialog &&
        !confirmationClicked
      ) {
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
      const latestSha = this.state.diffHeadSha;

      const options = {
        sha: latestSha || this.mr.sha,
        commit_message: this.commitMessage,
        auto_merge_strategy: useAutoMerge ? this.preferredAutoMergeStrategy : undefined,
        should_remove_source_branch: this.removeSourceBranch === true,
        squash: this.squashBeforeMerge,
        skip_merge_train: this.skipMergeTrain,
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

          this.updateGraphqlState();
        })
        .catch(() => {
          this.isMakingRequest = false;
          this.mr.transitionStateMachine({ transition: MERGE_FAILURE });
          createAlert({
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
    handleMergeTrainMergeImmediatelyButtonClick(type) {
      this.mergeTrainMergeType = type;
      this.isMergeTrainBeingForceMerged = true;
    },
    processMergeTrain() {
      if (this.mergeTrainMergeType === MT_SKIP_TRAIN) {
        this.skipMergeTrain = true;
      }

      this.handleMergeButtonClick(false, true, true);
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
          createAlert({
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
    appendCommitMessage(val) {
      this.commitMessage = `${this.commitMessage}\n\n${val}`;
      this.commitMessageIsTouched = true;
    },
  },
  i18n: {
    mergeCommitTemplateHintText: s__(
      'mrWidget|To change this default message, edit the template for merge commit messages. %{linkStart}Learn more%{linkEnd}.',
    ),
    squashCommitTemplateHintText: s__(
      'mrWidget|To change this default message, edit the template for squash commit messages. %{linkStart}Learn more%{linkEnd}.',
    ),
    mergeAndSquashCommitTemplatesHintText: s__(
      'mrWidget|To change these default messages, edit the templates for both the merge and squash commit messages. %{linkStart}Learn more%{linkEnd}.',
    ),
    sourceDivergedFromTargetText: s__('mrWidget|The source branch is %{link} the target branch.'),
    divergedCommits: (count) => n__('%d commit behind', '%d commits behind', count),
  },
  MT_SKIP_TRAIN,
  MT_RESTART_TRAIN,
};
</script>

<template>
  <div
    :class="{ 'gl-bg-gray-10': isNeitherClosedNorMerged }"
    data-testid="ready_to_merge_state"
    class="gl-border-t-1 gl-border-t-solid gl-border-gray-100 gl-pl-7"
  >
    <div v-if="loading" class="mr-widget-body">
      <div class="gl-w-full mr-ready-to-merge-loader">
        <gl-skeleton-loader :width="418" :height="86">
          <rect x="0" y="0" width="144" height="20" rx="4" />
          <rect x="0" y="26" width="100" height="16" rx="4" />
          <rect x="108" y="26" width="100" height="16" rx="4" />
          <rect x="0" y="48" width="130" height="16" rx="4" />
          <rect x="0" y="70" width="80" height="16" rx="4" />
          <rect x="88" y="70" width="90" height="16" rx="4" />
        </gl-skeleton-loader>
      </div>
    </div>
    <template v-else>
      <div
        class="mr-widget-body mr-widget-body-ready-merge media gl-display-flex gl-align-items-center"
      >
        <div class="media-body">
          <div class="mr-widget-body-controls gl-display-flex gl-align-items-center gl-flex-wrap">
            <template v-if="shouldShowMergeControls">
              <div
                class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-flex-wrap gl-w-full"
              >
                <gl-form-checkbox
                  v-if="canRemoveSourceBranch"
                  id="remove-source-branch-input"
                  v-model="removeSourceBranch"
                  :disabled="isRemoveSourceBranchButtonDisabled"
                  class="js-remove-source-branch-checkbox gl-display-flex gl-align-items-center gl-mr-5"
                  data-testid="delete-source-branch-checkbox"
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
                >
                  {{ __('Edit commit message') }}
                </gl-form-checkbox>
              </div>
              <div v-if="editCommitMessage" class="gl-w-full" data-testid="edit_commit_message">
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
                    data-testid="merge-commit-message"
                    @input="setCommitMessage"
                  >
                    <template #header>
                      <ai-commit-message
                        v-if="mr.aiCommitMessageEnabled"
                        :id="mr.id"
                        @update="appendCommitMessage"
                      />
                    </template>
                  </commit-edit>
                  <li class="gl-m-0! gl-p-0!">
                    <p class="form-text text-muted">
                      <gl-sprintf :message="commitTemplateHintText">
                        <template #link="{ content }">
                          <gl-link
                            :href="commitTemplateHelpPage"
                            class="inline-link"
                            target="_blank"
                            >{{ content }}</gl-link
                          >
                        </template>
                      </gl-sprintf>
                    </p>
                  </li>
                </ul>
              </div>
              <div class="gl-w-full gl-text-gray-500 gl-mb-3 mr-widget-merge-details">
                <template v-if="sourceHasDivergedFromTarget">
                  <gl-sprintf :message="$options.i18n.sourceDivergedFromTargetText">
                    <template #link>
                      <gl-link :href="mr.targetBranchPath">{{
                        $options.i18n.divergedCommits(mr.divergedCommitsCount)
                      }}</gl-link>
                    </template>
                  </gl-sprintf>
                  &middot;
                </template>
                <added-commit-message
                  :is-squash-enabled="squashBeforeMerge"
                  :is-fast-forward-enabled="!shouldShowMergeEdit"
                  :commits-count="commitsCount"
                  :target-branch="state.targetBranch"
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
              <gl-button-group class="gl-align-self-start">
                <gl-button
                  size="medium"
                  category="primary"
                  class="accept-merge-request"
                  data-testid="merge-button"
                  variant="confirm"
                  :disabled="isMergeButtonDisabled"
                  :loading="isMakingRequest"
                  @click="handleMergeButtonClick(isAutoMergeAvailable)"
                  >{{ mergeButtonText }}</gl-button
                >
                <gl-disclosure-dropdown
                  v-if="shouldShowMergeImmediatelyDropdown"
                  v-gl-tooltip.hover.focus="__('Select merge moment')"
                  :disabled="isMergeButtonDisabled"
                  variant="confirm"
                  class="gl-mr-0"
                  data-testid="merge-immediately-dropdown"
                  icon="chevron-down"
                  toggle-class="btn-icon js-merge-moment"
                  :toggle-text="__('Select a merge moment')"
                  text-sr-only
                  no-caret
                >
                  <gl-disclosure-dropdown-item
                    v-if="
                      !shouldDisplayMergeImmediatelyDropdownOptions || !isSkipMergeTrainAvailable
                    "
                    data-testid="merge-immediately-button"
                    @action="handleMergeImmediatelyButtonClick"
                  >
                    <template #list-item> {{ __('Merge immediately') }} </template>
                  </gl-disclosure-dropdown-item>
                  <gl-disclosure-dropdown-item
                    v-if="displaySkipMergeTrainOptions"
                    data-testid="mt-merge-now-restart-button"
                    @action="handleMergeTrainMergeImmediatelyButtonClick($options.MT_RESTART_TRAIN)"
                  >
                    <template #list-item>
                      <strong>{{ __(`Merge now and restart train`) }}</strong>
                      <p class="gl-text-gray-400 gl-font-sm gl-mb-0">
                        {{ __('Restart merge train pipelines with the merged changes.') }}
                      </p>
                    </template>
                  </gl-disclosure-dropdown-item>
                  <gl-disclosure-dropdown-item
                    v-if="displaySkipMergeTrainOptions"
                    data-testid="mt-merge-now-skip-restart-button"
                    @action="handleMergeTrainMergeImmediatelyButtonClick($options.MT_SKIP_TRAIN)"
                  >
                    <template #list-item>
                      <strong>{{ __(`Merge now and don't restart train`) }}</strong>
                      <p class="gl-text-gray-400 gl-font-sm gl-mb-0">
                        {{ __('Merge train pipelines continue without the merged changes.') }}
                      </p>
                    </template>
                  </gl-disclosure-dropdown-item>
                </gl-disclosure-dropdown>
              </gl-button-group>
              <template v-if="showAutoMergeHelperText">
                <div
                  class="gl-ml-4 gl-text-gray-500 gl-font-sm"
                  data-testid="auto-merge-helper-text"
                >
                  {{ autoMergeHelperText }}
                </div>
                <help-popover
                  class="gl-ml-2"
                  :options="autoMergeHelpPopoverOptions"
                  data-testid="auto-merge-helper-text-icon"
                >
                  <gl-sprintf :message="autoMergePopoverSettings.bodyText">
                    <template #link="{ content }">
                      <gl-link
                        :href="autoMergePopoverSettings.helpLink"
                        target="_blank"
                        class="gl-font-sm"
                      >
                        {{ content }}
                      </gl-link>
                    </template>
                  </gl-sprintf>
                </help-popover>
              </template>
            </template>
            <div
              v-else
              class="gl-w-full gl-order-n1 mr-widget-merge-details"
              data-testid="merged-status-content"
            >
              <p v-if="showMergeDetailsHeader" class="gl-mb-2 gl-text-gray-900">
                {{ __('Merge details') }}
              </p>
              <ul class="gl-pl-4 gl-mb-0 gl-ml-3 gl-text-gray-600">
                <li v-if="sourceHasDivergedFromTarget" class="gl-line-height-normal">
                  <gl-sprintf :message="$options.i18n.sourceDivergedFromTargetText">
                    <template #link>
                      <gl-link :href="mr.targetBranchPath">{{
                        $options.i18n.divergedCommits(mr.divergedCommitsCount)
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
                    :target-branch="state.targetBranch"
                    :merge-commit-path="mr.mergeCommitPath"
                  />
                </li>
                <li
                  v-if="isNotClosed"
                  class="gl-line-height-normal"
                  data-testid="source-branch-deleted-text"
                >
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
                <li v-if="state.autoMergeEnabled" class="gl-line-height-normal">
                  {{ s__('mrWidget|Auto-merge enabled') }}
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
      <merge-immediately-confirmation-dialog
        v-if="mr.mergeImmediatelyDocsPath"
        ref="confirmationDialog"
        :docs-url="mr.mergeImmediatelyDocsPath"
        @mergeImmediately="onMergeImmediatelyConfirmation"
      />
      <merge-train-failed-pipeline-confirmation-dialog
        :visible="isPipelineFailedModalVisibleMergeTrain"
        @startMergeTrain="onStartMergeTrainConfirmation"
        @cancel="isPipelineFailedModalVisibleMergeTrain = false"
      />
      <merge-train-restart-train-confirmation-dialog
        v-if="isSkipMergeTrainAvailable"
        :visible="isMergeTrainBeingForceMerged"
        :merge-train-type="mergeTrainMergeType"
        @processMergeTrainMerge="processMergeTrain"
        @cancel="isMergeTrainBeingForceMerged = false"
      />
      <merge-failed-pipeline-confirmation-dialog
        :visible="isPipelineFailedModalVisibleNormalMerge"
        :target-project-id="mr.targetProjectId"
        :iid="mr.iid"
        @mergeWithFailedPipeline="onMergeWithFailedPipelineConfirmation"
        @cancel="isPipelineFailedModalVisibleNormalMerge = false"
      />
    </template>
  </div>
</template>
