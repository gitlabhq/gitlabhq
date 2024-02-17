<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import DeploymentHistory from './components/deployment_history.vue';
import KubernetesOverview from './components/kubernetes/kubernetes_overview.vue';

export default {
  components: {
    GlTabs,
    GlTab,
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
  data() {
    return {
      currentTabIndex: 0,
    };
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
  },
};
</script>
<template>
  <gl-tabs v-model="currentTabIndex" sync-active-tab-with-query-params>
    <gl-tab
      :title="$options.i18n.kubernetesOverview"
      :query-param-value="$options.params.kubernetes"
      :title-link-class="linkClass(0)"
    >
      <kubernetes-overview
        :project-full-path="projectFullPath"
        :environment-name="environmentName"
      />
    </gl-tab>

    <gl-tab
      :title="$options.i18n.deploymentHistory"
      :query-param-value="$options.params.deployments"
      :title-link-class="linkClass(1)"
    >
      <deployment-history
        :project-full-path="projectFullPath"
        :environment-name="environmentName"
        :after="after"
        :before="before"
    /></gl-tab>
  </gl-tabs>
</template>
