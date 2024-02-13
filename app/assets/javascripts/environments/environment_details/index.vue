<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import DeploymentHistory from './components/deployment_history.vue';

export default {
  components: {
    GlTabs,
    GlTab,
    DeploymentHistory,
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
  i18n: {
    deploymentHistory: s__('Environments|Deployment history'),
  },
  params: {
    deployments: 'deployment-history',
  },
};
</script>
<template>
  <gl-tabs sync-active-tab-with-query-params>
    <gl-tab
      :title="$options.i18n.deploymentHistory"
      :query-param-value="$options.params.deployments"
    >
      <deployment-history
        :project-full-path="projectFullPath"
        :environment-name="environmentName"
        :after="after"
        :before="before"
    /></gl-tab>
  </gl-tabs>
</template>
