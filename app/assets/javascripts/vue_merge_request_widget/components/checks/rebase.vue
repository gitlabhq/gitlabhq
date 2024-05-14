<script>
import { GlModal, GlLink } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import simplePoll from '~/lib/utils/simple_poll';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import rebaseQuery from '../../queries/states/rebase.query.graphql';
import eventHub from '../../event_hub';
import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksRebase',
  components: {
    GlModal,
    GlLink,
    MergeChecksMessage,
    ActionButtons,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: rebaseQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest || null,
    },
  },
  inject: {
    canCreatePipelineInTargetProject: {
      default: false,
    },
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    service: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      state: null,
      isMakingRequest: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.state.loading || !this.state;
    },
    rebaseInProgress() {
      return this.state.rebaseInProgress;
    },
    showRebaseWithoutPipeline() {
      return (
        this.state.userPermissions.pushToSourceBranch &&
        (!this.mr.onlyAllowMergeIfPipelineSucceeds ||
          (this.mr.onlyAllowMergeIfPipelineSucceeds && this.mr.allowMergeOnSkippedPipeline))
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
    tertiaryActionsButtons() {
      return [
        this.state.userPermissions.pushToSourceBranch && {
          text: s__('mrWidget|Rebase'),
          loading: this.isMakingRequest || this.rebaseInProgress,
          testId: 'standard-rebase-button',
          onClick: () => this.tryRebase(),
        },
        this.showRebaseWithoutPipeline && {
          text: s__('mrWidget|Rebase without pipeline'),
          loading: this.isMakingRequest || this.rebaseInProgress,
          testId: 'rebase-without-ci-button',
          onClick: () => this.rebaseWithoutCi(),
        },
      ].filter((b) => b);
    },
  },
  methods: {
    rebase({ skipCi = false } = {}) {
      this.isMakingRequest = true;

      this.service
        .rebase({ skipCi })
        .then(() => simplePoll(this.checkRebaseStatus))
        .catch((error) => {
          this.isMakingRequest = false;

          if (!error.response?.data?.merge_error) {
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

            if (!res.merge_error?.length) {
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
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #failed>
      <action-buttons v-if="!isLoading" :tertiary-buttons="tertiaryActionsButtons" />
    </template>
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
  </merge-checks-message>
</template>
