<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlLoadingIcon, GlBanner, GlTabs, GlTab } from '@gitlab/ui';
import feedbackBannerIllustration from '@gitlab/svgs/dist/illustrations/chat-sm.svg?url';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import getAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_agents.query.graphql';
import getSharedAgentsQuery from 'ee_else_ce/clusters_list/graphql/queries/get_shared_agents.query.graphql';
import { AGENT_FEEDBACK_ISSUE, AGENT_FEEDBACK_KEY, KAS_DISABLED_ERROR } from '../constants';
import getTreeList from '../graphql/queries/get_tree_list.query.graphql';
import { getAgentLastContact, getAgentStatus } from '../clusters_util';
import AgentEmptyState from './agent_empty_state.vue';
import AgentTable from './agent_table.vue';
import AgentConfigsTable from './agents_configs_table.vue';

export default {
  i18n: {
    feedbackBannerTitle: s__('ClusterAgents|Tell us what you think'),
    feedbackBannerText: s__(
      'ClusterAgents|We would love to learn more about your experience with the GitLab Agent.',
    ),
    feedbackBannerButton: s__('ClusterAgents|Give feedback'),
    error: s__('ClusterAgents|An error occurred while loading your agents'),
    availableConfigs: s__('ClusterAgents|Available configurations'),
  },
  AGENT_FEEDBACK_ISSUE,
  AGENT_FEEDBACK_KEY,
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    agents: {
      query: getAgentsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        this.updateAgentsList(data);
      },
      result({ data }) {
        this.agentsCount = data?.project?.clusterAgents?.count;
        this.$emit('onAgentsLoad', this.agentsCount);
      },
      error(error) {
        this.queryErrored = true;

        if (error?.message?.indexOf(KAS_DISABLED_ERROR) >= 0) {
          this.$emit('kasDisabled', true);
        }
      },
    },
    sharedAgents: {
      query: getSharedAgentsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data;
      },
      error() {
        this.sharedAgentsQueryErrored = true;
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    treeList: {
      query: getTreeList,
      variables() {
        return {
          defaultBranchName: this.defaultBranchName,
          projectPath: this.projectPath,
        };
      },
      update(data) {
        this.updateTreeList(data);
        return data;
      },
    },
  },
  components: {
    AgentEmptyState,
    AgentTable,
    AgentConfigsTable,
    GlAlert,
    GlLoadingIcon,
    GlBanner,
    GlTabs,
    GlTab,
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
      folderList: {},
      feedbackBannerDismissed: false,
      queryErrored: false,
      sharedAgentsQueryErrored: false,
      sharedAgents: [],
      agentList: [],
      agentsCount: null,
      availableConfigs: [],
      configFolders: [],
      currentTab: 0,
    };
  },
  computed: {
    sharedAgentsList() {
      const sharedAgents = [
        ...(this.sharedAgents?.project?.ciAccessAuthorizedAgents?.nodes || []),
        ...(this.sharedAgents?.project?.userAccessAuthorizedAgents?.nodes || []),
      ];

      const filteredList = sharedAgents.filter((node, index, list) => {
        if (!node?.agent) return false;
        const isDuplicate = index !== list.findIndex((agent) => agent.agent.id === node.agent.id);
        const isSameProject = node.agent.project.fullPath === this.projectPath;
        return !isDuplicate && !isSameProject;
      });

      return filteredList
        .map(({ agent }) => {
          const lastContact = getAgentLastContact(agent?.tokens?.nodes);
          const status = getAgentStatus(lastContact);
          return { ...agent, lastContact, status, isShared: true };
        })
        .sort((a, b) => b.lastContact - a.lastContact);
    },
    agentListLoading() {
      return this.$apollo.queries.agents.loading;
    },
    sharedAgentsLoading() {
      return this.$apollo.queries.sharedAgents.loading;
    },
    feedbackBannerEnabled() {
      return this.glFeatures.showGitlabAgentFeedback;
    },
    feedbackBannerClasses() {
      return this.isChildComponent ? 'gl-my-2' : 'gl-mb-4';
    },
    feedbackBannerIllustration() {
      return feedbackBannerIllustration;
    },
    isLoading() {
      return this.agentListLoading && this.sharedAgentsLoading;
    },
    showEmptyState() {
      return (
        !this.queryErrored &&
        !this.agentList.length &&
        !this.sharedAgentsQueryErrored &&
        !this.sharedAgentsList.length
      );
    },
    showFeedbackBanner() {
      return this.feedbackBannerEnabled && (this.agentList.length || this.sharedAgentsList.length);
    },
    agentTabs() {
      const tabs = [];

      const projectAgents = {
        name: s__('ClusterAgents|Project agents'),
        count: this.agentsCount,
        agents: this.agentList,
        error: this.queryErrored,
        loading: this.agentListLoading,
      };

      const sharedAgents = {
        name: s__('ClusterAgents|Shared agents'),
        count: this.sharedAgentsList.length,
        agents: this.sharedAgentsList,
        error: this.sharedAgentsQueryErrored,
        loading: this.sharedAgentsLoading,
      };

      if (this.agentList.length > 0 || this.queryErrored) {
        tabs.push(projectAgents);
      }

      if (this.sharedAgentsList.length > 0 || this.sharedAgentsQueryErrored) {
        tabs.push(sharedAgents);
      }

      return tabs;
    },
  },
  methods: {
    findConfigFolder(agentName) {
      return this.configFolders?.find((folder) => folder.name === agentName);
    },
    updateTreeList(data) {
      this.configFolders = data?.project?.repository?.tree?.trees?.nodes;

      if (this.configFolders) {
        this.agentList = this.agentList.map((agent) => {
          const configFolder = this.findConfigFolder(agent.name);
          return { ...agent, configFolder };
        });

        this.updateConfigFolders();
      }
    },
    updateAgentsList(data) {
      const agents = data?.project?.clusterAgents?.nodes || [];
      this.agentList = agents
        .map((agent) => {
          const lastContact = getAgentLastContact(agent?.tokens?.nodes);
          const status = getAgentStatus(lastContact);
          const configFolder = this.findConfigFolder(agent.name);
          return { ...agent, lastContact, status, configFolder };
        })
        .sort((a, b) => {
          return b.lastContact - a.lastContact;
        });

      this.updateConfigFolders();
      this.currentTab = 0;
    },
    updateConfigFolders() {
      this.availableConfigs = this.configFolders.filter(
        (folder) => !this.agentList.find((agent) => agent.name === folder.name),
      );
    },

    handleBannerClose() {
      this.feedbackBannerDismissed = true;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <agent-empty-state v-else-if="showEmptyState" />

  <div v-else>
    <local-storage-sync
      v-if="showFeedbackBanner"
      v-model="feedbackBannerDismissed"
      :storage-key="$options.AGENT_FEEDBACK_KEY"
    >
      <gl-banner
        v-if="!feedbackBannerDismissed"
        :class="feedbackBannerClasses"
        :title="$options.i18n.feedbackBannerTitle"
        :button-text="$options.i18n.feedbackBannerButton"
        :button-link="$options.AGENT_FEEDBACK_ISSUE"
        :svg-path="feedbackBannerIllustration"
        @close="handleBannerClose"
      >
        <p>{{ $options.i18n.feedbackBannerText }}</p>
      </gl-banner>
    </local-storage-sync>

    <slot name="alerts"></slot>

    <gl-tabs v-model="currentTab">
      <gl-tab v-for="tab in agentTabs" :key="tab.name" :title="tab.name">
        <gl-loading-icon v-if="tab.loading" size="lg" />
        <gl-alert v-else-if="tab.error" variant="danger" :dismissible="false">
          {{ $options.i18n.error }}
        </gl-alert>

        <agent-table
          v-else
          :agents="tab.agents"
          :default-branch-name="defaultBranchName"
          :max-agents="limit"
        />
      </gl-tab>

      <gl-tab v-if="availableConfigs.length" :title="$options.i18n.availableConfigs">
        <agent-configs-table
          :configs="availableConfigs"
          :max-configs="limit"
          @registerAgent="$emit('registerAgent', $event)"
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
