<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterValues, setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import DeploymentHistory from './components/deployment_history.vue';
import KubernetesOverview from './components/kubernetes/kubernetes_overview.vue';

export default {
  components: {
    GlLoadingIcon,
    GlTabs,
    GlTab,
    GlBadge,
    DeploymentHistory,
    KubernetesOverview,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
    after: {
      type: String,
      required: false,
      default: null,
    },
    before: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    environment: {
      query: environmentClusterAgentQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
        };
      },
      update(data) {
        return data?.project?.environment;
      },
      result() {
        this.updateCurrentTab();
      },
    },
  },
  data() {
    return {
      currentTabIndex: 0,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.environment.loading;
    },
    kubernetesNamespace() {
      return this.environment?.kubernetesNamespace || '';
    },
    fluxResourcePath() {
      return this.environment?.fluxResourcePath || '';
    },
  },
  i18n: {
    deploymentHistory: s__('Environments|Deployment history'),
    kubernetesOverview: s__('Environments|Kubernetes overview'),
  },
  params: {
    deployments: 'deployment-history',
    kubernetes: 'kubernetes-overview',
  },
  methods: {
    linkClass(index) {
      return index === this.currentTabIndex ? 'gl-inset-border-b-2-theme-accent' : '';
    },
    updateCurrentTab() {
      const hasKubernetesIntegration = this.environment?.clusterAgent;
      const selectedTabFromUrl = getParameterValues('tab');

      // Note: We want to open the deployments history tab when
      // the Kubernetes integration is not set for the environment and
      // neither tab is preselected via URL param.
      if (!hasKubernetesIntegration && !selectedTabFromUrl.length) {
        updateHistory({
          url: setUrlParams({ tab: this.$options.params.deployments }),
          replace: true,
        });
      }
    },
  },
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" />
  <gl-tabs v-else v-model="currentTabIndex" sync-active-tab-with-query-params>
    <gl-tab
      :title="$options.i18n.kubernetesOverview"
      :query-param-value="$options.params.kubernetes"
      :title-link-class="linkClass(0)"
    >
      <kubernetes-overview
        :environment-name="environmentName"
        :cluster-agent="environment.clusterAgent"
        :kubernetes-namespace="kubernetesNamespace"
        :flux-resource-path="fluxResourcePath"
      />
    </gl-tab>

    <gl-tab :query-param-value="$options.params.deployments" :title-link-class="linkClass(1)">
      <template #title>
        {{ $options.i18n.deploymentHistory }}
        <gl-badge size="sm" class="gl-tab-counter-badge">{{
          environment.deploymentsDisplayCount
        }}</gl-badge>
      </template>

      <deployment-history
        :project-full-path="projectFullPath"
        :environment-name="environmentName"
        :after="after"
        :before="before"
    /></gl-tab>
  </gl-tabs>
</template>
