<script>
import { isEmpty } from 'lodash';
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fluxSyncStatus } from '~/environments/helpers/k8s_integration_helper';
import { DEPLOYMENT_KIND } from '~/environments/constants';
import KubernetesTreeItem from './kubernetes_tree_item.vue';

export default {
  components: {
    GlTab,
    KubernetesTreeItem,
  },
  i18n: {
    summaryTitle: s__('Environment|Summary'),
    treeView: s__('Environment|Tree view'),
  },
  props: {
    fluxKustomization: {
      required: true,
      type: Object,
    },
  },
  computed: {
    hasFluxKustomization() {
      return !isEmpty(this.fluxKustomization);
    },
    fluxKustomizationStatus() {
      if (!this.fluxKustomization.conditions?.length) return '';

      return fluxSyncStatus(this.fluxKustomization.conditions).status;
    },
    fluxInventory() {
      return (
        this.fluxKustomization?.inventory?.map((item) => {
          const [namespace, name, group, kind] = item.id.split('_');
          return { namespace, name, group, kind };
        }) || []
      );
    },
    fluxInventoryDeployments() {
      return this.fluxInventory?.filter((item) => item.kind === DEPLOYMENT_KIND);
    },
  },
  methods: {
    isLast(index) {
      return index === this.fluxInventoryDeployments.length - 1;
    },
  },
};
</script>
<template>
  <gl-tab :title="$options.i18n.summaryTitle">
    <p class="gl-mt-3 gl-text-secondary">{{ $options.i18n.treeView }}</p>

    <div
      class="gl-flex gl-items-start gl-overflow-x-auto gl-overflow-y-hidden kubernetes-tree-view"
    >
      <kubernetes-tree-item
        v-if="hasFluxKustomization"
        :kind="fluxKustomization.kind"
        :name="fluxKustomization.metadata.name"
        :status="fluxKustomizationStatus"
      />

      <div v-if="fluxInventoryDeployments.length" class="gl-ml-6" data-testid="related-deployments">
        <div
          v-for="(deployment, index) of fluxInventoryDeployments"
          :key="deployment.name"
          class="gl-relative"
        >
          <div
            class="connector gl-border-1 gl-border-t-solid gl-border-gray-200 gl-absolute gl-z-0 gl-top-1/2 gl-right-1/2"
            :class="{
              'gl-border-l-solid': !isLast(index),
            }"
          ></div>
          <kubernetes-tree-item :kind="deployment.kind" :name="deployment.name" class="gl-mb-4" />
        </div>
      </div>
    </div>
  </gl-tab>
</template>
