<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { CLUSTERS_TABS, MAX_CLUSTERS_LIST, MAX_LIST_COUNT, AGENT } from '../constants';
import Agents from './agents.vue';
import InstallAgentModal from './install_agent_modal.vue';
import ClustersActions from './clusters_actions.vue';
import Clusters from './clusters.vue';
import ClustersViewAll from './clusters_view_all.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    ClustersActions,
    ClustersViewAll,
    Clusters,
    Agents,
    InstallAgentModal,
  },
  CLUSTERS_TABS,
  props: {
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
  },
  data() {
    return {
      selectedTabIndex: 0,
      maxAgents: MAX_CLUSTERS_LIST,
    };
  },
  methods: {
    onTabChange(tabName) {
      this.selectedTabIndex = CLUSTERS_TABS.findIndex((tab) => tab.queryParamValue === tabName);

      this.maxAgents = tabName === AGENT ? MAX_LIST_COUNT : MAX_CLUSTERS_LIST;
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs
      v-model="selectedTabIndex"
      sync-active-tab-with-query-params
      nav-class="gl-flex-grow-1 gl-align-items-center"
      lazy
    >
      <gl-tab
        v-for="(tab, idx) in $options.CLUSTERS_TABS"
        :key="idx"
        :title="tab.title"
        :query-param-value="tab.queryParamValue"
        class="gl-line-height-20 gl-mt-5"
      >
        <component
          :is="tab.component"
          :default-branch-name="defaultBranchName"
          data-testid="clusters-tab-component"
          @changeTab="onTabChange"
        />
      </gl-tab>

      <template #tabs-end>
        <clusters-actions />
      </template>
    </gl-tabs>

    <install-agent-modal :default-branch-name="defaultBranchName" :max-agents="maxAgents" />
  </div>
</template>
