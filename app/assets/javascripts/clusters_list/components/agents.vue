<script>
import { GlAlert, GlKeysetPagination, GlLoadingIcon, GlBanner } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  MAX_LIST_COUNT,
  ACTIVE_CONNECTION_TIME,
  AGENT_FEEDBACK_ISSUE,
  AGENT_FEEDBACK_KEY,
} from '../constants';
import getAgentsQuery from '../graphql/queries/get_agents.query.graphql';
import AgentEmptyState from './agent_empty_state.vue';
import AgentTable from './agent_table.vue';

export default {
  i18n: {
    feedbackBannerTitle: s__('ClusterAgents|Tell us what you think'),
    feedbackBannerText: s__(
      'ClusterAgents|We would love to learn more about your experience with the GitLab Agent.',
    ),
    feedbackBannerButton: s__('ClusterAgents|Give feedback'),
    error: s__('ClusterAgents|An error occurred while loading your Agents'),
  },
  AGENT_FEEDBACK_ISSUE,
  AGENT_FEEDBACK_KEY,
  apollo: {
    agents: {
      query: getAgentsQuery,
      variables() {
        return {
          defaultBranchName: this.defaultBranchName,
          projectPath: this.projectPath,
          ...this.cursor,
        };
      },
      update(data) {
        this.updateTreeList(data);
        return data;
      },
      result() {
        this.emitAgentsLoaded();
      },
    },
  },
  components: {
    AgentEmptyState,
    AgentTable,
    GlAlert,
    GlKeysetPagination,
    GlLoadingIcon,
    GlBanner,
    LocalStorageSync,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['projectPath'],
  props: {
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
    isChildComponent: {
      default: false,
      required: false,
      type: Boolean,
    },
    limit: {
      default: null,
      required: false,
      type: Number,
    },
  },
  data() {
    return {
      cursor: {
        first: this.limit ? this.limit : MAX_LIST_COUNT,
        last: null,
      },
      folderList: {},
      feedbackBannerDismissed: false,
    };
  },
  computed: {
    agentList() {
      let list = this.agents?.project?.clusterAgents?.nodes;

      if (list) {
        list = list.map((agent) => {
          const configFolder = this.folderList[agent.name];
          const lastContact = this.getLastContact(agent);
          const status = this.getStatus(lastContact);
          return { ...agent, configFolder, lastContact, status };
        });
      }

      return list;
    },
    agentPageInfo() {
      return this.agents?.project?.clusterAgents?.pageInfo || {};
    },
    isLoading() {
      return this.$apollo.queries.agents.loading;
    },
    showPagination() {
      return !this.limit && (this.agentPageInfo.hasPreviousPage || this.agentPageInfo.hasNextPage);
    },
    treePageInfo() {
      return this.agents?.project?.repository?.tree?.trees?.pageInfo || {};
    },
    feedbackBannerEnabled() {
      return this.glFeatures.showGitlabAgentFeedback;
    },
    feedbackBannerClasses() {
      return this.isChildComponent ? 'gl-my-2' : 'gl-mb-4';
    },
  },
  methods: {
    reloadAgents() {
      this.$apollo.queries.agents.refetch();
    },
    nextPage() {
      this.cursor = {
        first: MAX_LIST_COUNT,
        last: null,
        afterAgent: this.agentPageInfo.endCursor,
        afterTree: this.treePageInfo.endCursor,
      };
    },
    prevPage() {
      this.cursor = {
        first: null,
        last: MAX_LIST_COUNT,
        beforeAgent: this.agentPageInfo.startCursor,
        beforeTree: this.treePageInfo.endCursor,
      };
    },
    updateTreeList(data) {
      const configFolders = data?.project?.repository?.tree?.trees?.nodes;

      if (configFolders) {
        configFolders.forEach((folder) => {
          this.folderList[folder.name] = folder;
        });
      }
    },
    getLastContact(agent) {
      const tokens = agent?.tokens?.nodes;
      let lastContact = null;
      if (tokens?.length) {
        tokens.forEach((token) => {
          const lastContactToDate = new Date(token.lastUsedAt).getTime();
          if (lastContactToDate > lastContact) {
            lastContact = lastContactToDate;
          }
        });
      }
      return lastContact;
    },
    getStatus(lastContact) {
      if (lastContact) {
        const now = new Date().getTime();
        const diff = now - lastContact;

        return diff > ACTIVE_CONNECTION_TIME ? 'inactive' : 'active';
      }
      return 'unused';
    },
    emitAgentsLoaded() {
      const count = this.agents?.project?.clusterAgents?.count;
      this.$emit('onAgentsLoad', count);
    },
    handleBannerClose() {
      this.feedbackBannerDismissed = true;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" />

  <section v-else-if="agentList">
    <div v-if="agentList.length">
      <local-storage-sync
        v-if="feedbackBannerEnabled"
        v-model="feedbackBannerDismissed"
        :storage-key="$options.AGENT_FEEDBACK_KEY"
      >
        <gl-banner
          v-if="!feedbackBannerDismissed"
          variant="introduction"
          :class="feedbackBannerClasses"
          :title="$options.i18n.feedbackBannerTitle"
          :button-text="$options.i18n.feedbackBannerButton"
          :button-link="$options.AGENT_FEEDBACK_ISSUE"
          @close="handleBannerClose"
        >
          <p>{{ $options.i18n.feedbackBannerText }}</p>
        </gl-banner>
      </local-storage-sync>

      <agent-table
        :agents="agentList"
        :default-branch-name="defaultBranchName"
        :max-agents="cursor.first"
      />

      <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
        <gl-keyset-pagination v-bind="agentPageInfo" @prev="prevPage" @next="nextPage" />
      </div>
    </div>

    <agent-empty-state v-else :is-child-component="isChildComponent" />
  </section>

  <gl-alert v-else variant="danger" :dismissible="false">
    {{ $options.i18n.error }}
  </gl-alert>
</template>
