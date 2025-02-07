<script>
import { GlTabs, GlTab, GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import Tracking from '~/tracking';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  CLUSTERS_TABS,
  CERTIFICATE_TAB,
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
  i18n: {
    alertTitle: s__('ClusterAgents|%{agentName} successfully created'),
    alertText: s__(
      'ClusterAgents|Optionally, for additional configuration settings, a %{linkStart}configuration file%{linkEnd} can be created in the repository. You can do so within the default branch by creating the file at: %{codeStart}.gitlab/agents/%{agentName}/config.yaml%{codeEnd}',
    ),
  },
  configurationDocsLink: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'create-an-agent-configuration-file',
  }),
  components: {
    GlTabs,
    GlTab,
    GlAlert,
    GlSprintf,
    GlLink,
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
      kasDisabled: false,
      newAgentName: null,
      showNewAgentAlert: false,
      hasAgentConfig: false,
    };
  },
  computed: {
    availableTabs() {
      const clusterTabs = this.displayClusterAgents ? CLUSTERS_TABS : [CERTIFICATE_TAB];
      return this.certificateBasedClustersEnabled ? clusterTabs : [AGENT_TAB];
    },
    alertTitle() {
      return sprintf(this.$options.i18n.alertTitle, {
        agentName: this.newAgentName,
      });
    },
    alertText() {
      return sprintf(this.$options.i18n.alertText, {
        agentName: this.newAgentName,
      });
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

      this.track(EVENT_ACTIONS_CHANGE, { property: tabName });
    },
    clusterAgentCreated(name) {
      this.newAgentName = name;
      if (!this.hasAgentConfig) {
        this.showNewAgentAlert = true;
      }
    },
    closeNewAgentAlert() {
      this.showNewAgentAlert = false;
    },
    openRegistrationModal(name) {
      this.hasAgentConfig = true;
      this.$refs.installAgentModal.showModalForAgent(name);
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs
      v-model="selectedTabIndex"
      sync-active-tab-with-query-params
      nav-class="gl-grow gl-items-center"
      lazy
    >
      <gl-tab
        v-for="(tab, idx) in availableTabs"
        :key="idx"
        :title="tab.title"
        :query-param-value="tab.queryParamValue"
        class="gl-mt-5 gl-leading-20"
      >
        <component
          :is="tab.component"
          :default-branch-name="defaultBranchName"
          data-testid="clusters-tab-component"
          @changeTab="setSelectedTab"
          @kasDisabled="kasDisabled = $event"
          @registerAgent="openRegistrationModal"
        >
          <template #alerts>
            <gl-alert
              v-if="showNewAgentAlert"
              :title="alertTitle"
              variant="success"
              class="gl-mb-4"
              @dismiss="closeNewAgentAlert"
            >
              <gl-sprintf :message="alertText">
                <template #link="{ content }"
                  ><gl-link :href="$options.configurationDocsLink">{{ content }}</gl-link></template
                >
                <template #code="{ content }">
                  <code>{{ content }}</code>
                </template>
              </gl-sprintf>
            </gl-alert>
          </template>
        </component>
      </gl-tab>

      <template #tabs-end>
        <clusters-actions />
      </template>
    </gl-tabs>
    <install-agent-modal
      ref="installAgentModal"
      :kas-disabled="kasDisabled"
      @clusterAgentCreated="clusterAgentCreated"
    />
  </div>
</template>
