<script>
import { GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import MrCollapsibleExtension from '../mr_collapsible_extension.vue';

export default {
  components: {
    Deployment: () => import('./deployment.vue'),
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
    visualReviewAppMeta: {
      type: Object,
      required: false,
      default: () => ({
        sourceProjectId: '',
        sourceProjectPath: '',
        mergeRequestId: '',
        appUrl: '',
      }),
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
  <mr-collapsible-extension
    v-if="showCollapsedDeployments"
    :title="__('View all environments.')"
    data-testid="mr-collapsed-deployments"
  >
    <template #header>
      <div class="gl-mr-3 gl-line-height-normal">
        <gl-sprintf :message="multipleDeploymentsTitle">
          <template #deployments>
            <span class="gl-font-weight-bold gl-mr-2">{{ deployments.length }}</span>
          </template>
        </gl-sprintf>
      </div>
    </template>
    <deployment
      v-for="deployment in deployments"
      :key="deployment.id"
      :class="deploymentClass"
      class="gl-bg-gray-50"
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
