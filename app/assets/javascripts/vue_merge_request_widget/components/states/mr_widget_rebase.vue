<script>
import { GlButton, GlLink, GlModal, GlSkeletonLoader } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import simplePoll from '~/lib/utils/simple_poll';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import rebaseQuery from '../../queries/states/rebase.query.graphql';
import StateContainer from '../state_container.vue';

const i18n = {
  rebaseError: s__(
    'mrWidget|%{boldStart}Merge blocked:%{boldEnd} the source branch must be rebased onto the target branch.',
  ),
};

export default {
  name: 'MRWidgetRebase',
  i18n,
  modal: {
    id: 'rebase-security-risk-modal',
    title: s__('mrWidget|Are you sure you want to rebase?'),
    actionPrimary: {
      text: s__('mrWidget|Rebase'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  runPipelinesInTheParentProjectHelpPath: helpPagePath(
    '/ci/pipelines/merge_request_pipelines.html',
    {
      anchor: 'run-pipelines-in-the-parent-project',
    },
  ),
  apollo: {
    state: {
      query: rebaseQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest || {},
    },
  },
  components: {
    BoldText,
    GlButton,
    GlLink,
    GlModal,
    GlSkeletonLoader,
    StateContainer,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  inject: {
    canCreatePipelineInTargetProject: {
      default: false,
    },
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: {},
      isMakingRequest: false,
      rebasingError: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.state.loading;
    },
    rebaseInProgress() {
      return this.state.rebaseInProgress;
    },
    canPushToSourceBranch() {
      return this.state.userPermissions?.pushToSourceBranch || false;
    },
    targetBranch() {
      return this.state.targetBranch;
    },
    status() {
      if (this.isLoading) {
        return undefined;
      }

      if (this.rebaseInProgress || this.isMakingRequest) {
        return 'loading';
      }
      if (!this.canPushToSourceBranch && !this.rebaseInProgress) {
        return 'failed';
      }
      return 'success';
    },
    showRebaseWithoutPipeline() {
      return (
        !this.mr.onlyAllowMergeIfPipelineSucceeds ||
        (this.mr.onlyAllowMergeIfPipelineSucceeds && this.mr.allowMergeOnSkippedPipeline)
      );
    },
    isForkMergeRequest() {
      return this.mr.sourceProjectFullPath !== this.mr.targetProjectFullPath;
    },
    isLatestPipelineCreatedInTargetProject() {
      const latestPipeline = this.state.pipelines.nodes[0];

      return latestPipeline?.project?.fullPath === this.mr.targetProjectFullPath;
    },
    shouldShowSecurityWarning() {
      return (
        this.canCreatePipelineInTargetProject &&
        this.isForkMergeRequest &&
        !this.isLatestPipelineCreatedInTargetProject
      );
    },
  },
  methods: {
    rebase({ skipCi = false } = {}) {
      this.isMakingRequest = true;
      this.rebasingError = null;

      this.service
        .rebase({ skipCi })
        .then(() => {
          simplePoll(this.checkRebaseStatus);
        })
        .catch((error) => {
          this.isMakingRequest = false;

          if (error.response && error.response.data && error.response.data.merge_error) {
            this.rebasingError = error.response.data.merge_error;
          } else {
            createAlert({
              message: __('Something went wrong. Please try again.'),
            });
          }
        });
    },
    rebaseWithoutCi() {
      return this.rebase({ skipCi: true });
    },
    tryRebase() {
      if (this.shouldShowSecurityWarning) {
        this.$refs.modal.show();
      } else {
        this.rebase();
      }
    },
    checkRebaseStatus(continuePolling, stopPolling) {
      this.service
        .poll()
        .then((res) => res.data)
        .then((res) => {
          if (res.rebase_in_progress || res.should_be_rebased) {
            continuePolling();
          } else {
            this.isMakingRequest = false;

            if (res.merge_error && res.merge_error.length) {
              this.rebasingError = res.merge_error;
            } else {
              toast(__('Rebase completed'));
            }

            eventHub.$emit('MRWidgetRebaseSuccess');
            stopPolling();
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
          stopPolling();
        });
    },
  },
};
</script>
<template>
  <div>
    <state-container
      :status="status"
      :is-loading="isLoading"
      is-collapsible
      :collapsed="mr.mergeDetailsCollapsed"
      @toggle="() => mr.toggleMergeDetails()"
    >
      <template #loading>
        <gl-skeleton-loader :width="334" :height="24">
          <rect x="0" y="0" width="24" height="24" rx="4" />
          <rect x="32" y="2" width="302" height="20" rx="4" />
        </gl-skeleton-loader>
      </template>
      <template v-if="!isLoading">
        <span
          v-if="rebaseInProgress || isMakingRequest"
          class="gl-ml-0! gl-text-body!"
          data-testid="rebase-message"
          >{{ s__('mrWidget|Rebase in progress') }}</span
        >
        <span
          v-if="!rebaseInProgress && !canPushToSourceBranch"
          class="gl-text-body! gl-ml-0!"
          data-testid="rebase-message"
        >
          <bold-text :message="$options.i18n.rebaseError" />
        </span>
        <div
          v-if="!rebaseInProgress && canPushToSourceBranch && !isMakingRequest"
          class="accept-merge-holder clearfix js-toggle-container media gl-md-display-flex gl-flex-wrap gl-flex-grow-1"
        >
          <span
            v-if="!rebasingError"
            class="gl-w-full gl-md-w-auto gl-flex-grow-1 gl-ml-0! gl-text-body! gl-md-mr-3"
            data-testid="rebase-message"
          >
            <bold-text :message="$options.i18n.rebaseError" />
          </span>
          <span
            v-else
            class="gl-font-weight-bold danger gl-w-full gl-md-w-auto gl-flex-grow-1 gl-md-mr-3"
            data-testid="rebase-message"
            >{{ rebasingError }}</span
          >
        </div>
      </template>
      <template v-if="!isLoading" #actions>
        <gl-button
          :loading="isMakingRequest"
          variant="confirm"
          size="small"
          data-testid="standard-rebase-button"
          class="gl-align-self-start"
          @click="tryRebase"
        >
          {{ s__('mrWidget|Rebase') }}
        </gl-button>
        <gl-button
          v-if="showRebaseWithoutPipeline"
          :loading="isMakingRequest"
          variant="confirm"
          size="small"
          category="secondary"
          data-testid="rebase-without-ci-button"
          class="gl-align-self-start gl-mr-2"
          @click="rebaseWithoutCi"
        >
          {{ s__('mrWidget|Rebase without pipeline') }}
        </gl-button>
      </template>
    </state-container>

    <gl-modal
      ref="modal"
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="rebase"
    >
      <p>
        {{
          s__(
            'Pipelines|Rebasing creates a pipeline that runs code originating from a forked project merge request. Consequently there are potential security implications, such as the exposure of CI variables.',
          )
        }}
      </p>
      <p>
        {{
          s__(
            "Pipelines|You should review the code thoroughly before running this pipeline with the parent project's CI/CD resources.",
          )
        }}
      </p>
      <p>
        {{ s__('Pipelines|If you are unsure, ask a project maintainer to review it for you.') }}
      </p>
      <gl-link :href="$options.runPipelinesInTheParentProjectHelpPath" target="_blank">
        {{ s__('Pipelines|More Information') }}
      </gl-link>
    </gl-modal>
  </div>
</template>
