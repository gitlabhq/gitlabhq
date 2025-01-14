<script>
import { GlTooltipDirective, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import getRefMixin from '../mixins/get_ref';
import { getRefType } from '../utils/ref_type';
import projectPathQuery from '../queries/project_path.query.graphql';
import eventHub from '../event_hub';
import { FORK_UPDATED_EVENT } from '../constants';
import CommitInfo from './commit_info.vue';
import CollapsibleCommitInfo from './collapsible_commit_info.vue';

export default {
  components: {
    CommitInfo,
    CollapsibleCommitInfo,
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
  <gl-loading-icon v-if="isLoading" size="md" color="dark" class="gl-m-auto gl-py-6" />

  <div v-else-if="commit">
    <commit-info :commit="commit" class="gl-hidden sm:gl-flex">
      <div class="commit-actions gl-my-2 gl-flex gl-items-start gl-gap-3">
        <signature-badge v-if="commit.signature" :signature="commit.signature" class="gl-h-7" />
        <div v-if="commit.pipeline" class="gl-ml-5 gl-flex gl-h-7 gl-items-center">
          <ci-icon
            :status="commit.pipeline.detailedStatus"
            :aria-label="statusTitle"
            class="js-commit-pipeline gl-mr-2"
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
