<script>
import { GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import MrCollapsibleExtension from '../mr_collapsible_extension.vue';
import Deployment from './deployment.vue';

export default {
  components: {
    Deployment,
    GlSprintf,
    MrCollapsibleExtension,
  },
  props: {
    deployments: {
      type: Array,
      required: true,
    },
    deploymentClass: {
      type: String,
      required: true,
    },
    hasDeploymentMetrics: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showCollapsedDeployments() {
      return this.deployments.length > 3;
    },
    multipleDeploymentsTitle() {
      return n__(
        'Deployments|%{deployments} environment impacted.',
        'Deployments|%{deployments} environments impacted.',
        this.deployments.length,
      );
    },
  },
};
</script>
<template>
  <mr-collapsible-extension v-if="showCollapsedDeployments" :title="__('View all environments.')">
    <template #header>
      <div class="gl-mr-3 gl-leading-normal">
        <gl-sprintf :message="multipleDeploymentsTitle">
          <template #deployments>
            <span class="gl-mr-2 gl-font-bold">{{ deployments.length }}</span>
          </template>
        </gl-sprintf>
      </div>
    </template>
    <deployment
      v-for="deployment in deployments"
      :key="deployment.id"
      :class="deploymentClass"
      :deployment="deployment"
      :show-metrics="hasDeploymentMetrics"
    />
  </mr-collapsible-extension>
  <div v-else class="mr-widget-extension">
    <deployment
      v-for="deployment in deployments"
      :key="deployment.id"
      :class="deploymentClass"
      :deployment="deployment"
      :show-metrics="hasDeploymentMetrics"
    />
  </div>
</template>
