<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import Tracking from '~/tracking';
import {
  CLUSTERS_TABS,
  MAX_CLUSTERS_LIST,
  MAX_LIST_COUNT,
  AGENT,
  EVENT_LABEL_TABS,
  EVENT_ACTIONS_CHANGE,
} from '../constants';
import Agents from './agents.vue';
import InstallAgentModal from './install_agent_modal.vue';
import ClustersActions from './clusters_actions.vue';
import Clusters from './clusters.vue';
import ClustersViewAll from './clusters_view_all.vue';

const trackingMixin = Tracking.mixin({ label: EVENT_LABEL_TABS });

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
  mixins: [trackingMixin],
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
  watch: {
    selectedTabIndex(val) {
      this.onTabChange(val);
    },
  },
  methods: {
    setSelectedTab(tabName) {
      this.selectedTabIndex = CLUSTERS_TABS.findIndex((tab) => tab.queryParamValue === tabName);
    },
    onTabChange(tab) {
      const tabName = CLUSTERS_TABS[tab].queryParamValue;

      this.maxAgents = tabName === AGENT ? MAX_LIST_COUNT : MAX_CLUSTERS_LIST;
      this.track(EVENT_ACTIONS_CHANGE, { property: tabName });
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
          @changeTab="setSelectedTab"
        />
      </gl-tab>

      <template #tabs-end>
        <clusters-actions />
      </template>
    </gl-tabs>

    <install-agent-modal :default-branch-name="defaultBranchName" :max-agents="maxAgents" />
  </div>
</template>
