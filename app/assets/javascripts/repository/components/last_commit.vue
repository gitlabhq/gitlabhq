<script>
import { GlTooltipDirective, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import eventHub from '../event_hub';
import { FORK_UPDATED_EVENT } from '../constants';
import CommitInfo from './commit_info.vue';

export default {
  components: {
    CommitInfo,
    ClipboardButton,
    SignatureBadge,
    CiIcon,
    GlButtonGroup,
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [getRefMixin],
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
          refType: this.refType?.toUpperCase(),
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
  },
  data() {
    return {
      projectPath: '',
      commit: null,
    };
  },
  computed: {
    statusTitle() {
      return sprintf(s__('PipelineStatusTooltip|Pipeline: %{ciStatus}'), {
        ciStatus: this.commit?.pipeline?.detailedStatus?.text,
      });
    },
    isLoading() {
      return this.$apollo.queries.commit.loading;
    },
    showCommitId() {
      return this.commit?.sha?.substr(0, 8);
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
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" color="dark" class="m-auto gl-min-h-8 gl-py-6" />
  <commit-info v-else-if="commit" :commit="commit">
    <div
      class="commit-actions gl-display-flex gl-flex-align gl-align-items-center gl-flex-direction-row"
    >
      <signature-badge v-if="commit.signature" :signature="commit.signature" />
      <div v-if="commit.pipeline" class="gl-ml-5">
        <ci-icon
          :status="commit.pipeline.detailedStatus"
          :aria-label="statusTitle"
          class="js-commit-pipeline"
        />
      </div>
      <gl-button-group class="gl-ml-4 js-commit-sha-group">
        <gl-button label class="gl-font-monospace" data-testid="last-commit-id-label">{{
          showCommitId
        }}</gl-button>
        <clipboard-button
          :text="commit.sha"
          :title="__('Copy commit SHA')"
          class="input-group-text"
        />
      </gl-button-group>
    </div>
  </commit-info>
</template>
