<script>
import { isEmpty } from 'lodash';
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fluxSyncStatus } from '~/environments/helpers/k8s_integration_helper';
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
  },
};
</script>
<template>
  <gl-tab :title="$options.i18n.summaryTitle">
    <p class="gl-mt-3 gl-text-secondary">{{ $options.i18n.treeView }}</p>

    <kubernetes-tree-item
      v-if="hasFluxKustomization"
      :kind="fluxKustomization.kind"
      :name="fluxKustomization.metadata.name"
      :status="fluxKustomizationStatus"
    />
  </gl-tab>
</template>
