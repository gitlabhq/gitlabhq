<script>
import { GlTooltipDirective, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { HISTORY_BUTTON_CLICK } from '~/tracking/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import PipelineCiStatus from '~/vue_shared/components/ci_status/pipeline_ci_status.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getRefMixin from '../mixins/get_ref';
import { getRefType } from '../utils/ref_type';
import projectPathQuery from '../queries/project_path.query.graphql';
import eventHub from '../event_hub';
import { FORK_UPDATED_EVENT } from '../constants';
import CommitInfo from './commit_info.vue';
import CollapsibleCommitInfo from './collapsible_commit_info.vue';

const trackingMixin = InternalEvents.mixin();
export default {
  components: {
    CommitInfo,
    CollapsibleCommitInfo,
    ClipboardButton,
    SignatureBadge,
    GlButtonGroup,
    GlButton,
    GlLoadingIcon,
    PipelineCiStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [getRefMixin, glFeatureFlagMixin(), trackingMixin],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
    commit: {
      query: pathLastCommitQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ref: this.ref,
          refType: getRefType(this.refType),
          path: this.currentPath.replace(/^\//, ''),
        };
      },
      update: (data) => {
        const lastCommit = data.project?.repository?.paginatedTree?.nodes[0]?.lastCommit;
        const pipelines = lastCommit?.pipelines?.edges;

        return {
          ...lastCommit,
          pipeline: pipelines?.length && pipelines[0].node,
        };
      },
      error(error) {
        throw error;
      },
      pollInterval: 30000,
    },
  },
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
    refType: {
      type: String,
      required: false,
      default: null,
    },
    historyUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      projectPath: '',
      commit: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.commit.loading;
    },
    showCommitId() {
      return this.commit?.sha?.substr(0, 8);
    },
    showRealTimePipelineStatus() {
      return this.glFeatures.ciPipelineStatusRealtime;
    },
  },
  watch: {
    currentPath() {
      this.commit = null;
    },
  },
  mounted() {
    eventHub.$on(FORK_UPDATED_EVENT, this.refetchLastCommit);
  },
  beforeDestroy() {
    eventHub.$off(FORK_UPDATED_EVENT, this.refetchLastCommit);
  },
  methods: {
    refetchLastCommit() {
      this.$apollo.queries.commit.refetch();
    },
    handleHistoryClick() {
      this.trackEvent(HISTORY_BUTTON_CLICK);
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" color="dark" class="gl-m-auto gl-py-6" />

  <div v-else-if="commit">
    <commit-info :commit="commit" class="gl-hidden sm:gl-flex">
      <div class="commit-actions gl-my-2 gl-flex gl-items-start gl-gap-3">
        <signature-badge v-if="commit.signature" :signature="commit.signature" class="gl-h-7" />
        <div v-if="commit.pipeline.id" class="gl-ml-5 gl-flex gl-h-7 gl-items-center">
          <pipeline-ci-status
            :pipeline-id="commit.pipeline.id"
            :project-full-path="projectPath"
            :can-subscribe="showRealTimePipelineStatus"
            class="gl-mr-2"
          />
        </div>
        <gl-button-group class="js-commit-sha-group gl-ml-4 gl-flex gl-items-center">
          <gl-button
            label
            class="gl-font-monospace dark:!gl-bg-strong"
            data-testid="last-commit-id-label"
            >{{ showCommitId }}</gl-button
          >
          <clipboard-button
            :text="commit.sha"
            :title="__('Copy commit SHA')"
            class="input-group-text dark:!gl-border-l-section"
          />
        </gl-button-group>
        <gl-button
          category="secondary"
          data-testid="last-commit-history"
          :href="historyUrl"
          class="!gl-ml-0"
          @click="handleHistoryClick"
        >
          {{ __('History') }}
        </gl-button>
      </div>
    </commit-info>
    <collapsible-commit-info
      :commit="commit"
      :history-url="historyUrl"
      class="gl-block !gl-border-t-0 sm:gl-hidden"
    />
  </div>
</template>
