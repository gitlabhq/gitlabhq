<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import Tracking from '~/tracking';
import {
  CLUSTERS_TABS,
  CERTIFICATE_TAB,
  MAX_CLUSTERS_LIST,
  MAX_LIST_COUNT,
  AGENT,
  EVENT_LABEL_TABS,
  EVENT_ACTIONS_CHANGE,
  AGENT_TAB,
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
  mixins: [trackingMixin],
  inject: ['displayClusterAgents', 'certificateBasedClustersEnabled'],
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
  computed: {
    availableTabs() {
      const clusterTabs = this.displayClusterAgents ? CLUSTERS_TABS : [CERTIFICATE_TAB];
      return this.certificateBasedClustersEnabled ? clusterTabs : [AGENT_TAB];
    },
  },
  watch: {
    selectedTabIndex: {
      handler(val) {
        this.onTabChange(val);
      },
      immediate: true,
    },
  },
  methods: {
    setSelectedTab(tabName) {
      this.selectedTabIndex = this.availableTabs.findIndex(
        (tab) => tab.queryParamValue === tabName,
      );
    },
    onTabChange(tab) {
      const tabName = this.availableTabs[tab].queryParamValue;

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
        v-for="(tab, idx) in availableTabs"
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
