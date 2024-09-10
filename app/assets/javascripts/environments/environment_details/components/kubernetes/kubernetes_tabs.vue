<script>
import { GlTabs } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesServices from './kubernetes_services.vue';
import KubernetesSummary from './kubernetes_summary.vue';

const defaultTabs = [k8sResourceType.k8sPods, k8sResourceType.k8sServices];
const tabsWithSummary = ['summary', ...defaultTabs];

export default {
  components: {
    GlTabs,
    KubernetesPods,
    KubernetesServices,
    KubernetesSummary,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    configuration: {
      required: true,
      type: Object,
    },
    namespace: {
      required: true,
      type: String,
    },
    value: {
      required: true,
      type: String,
    },
    fluxKustomization: {
      required: false,
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      activeTabIndex: this.glFeatures.k8sTreeView
        ? tabsWithSummary.indexOf(this.value)
        : defaultTabs.indexOf(this.value),
    };
  },
  computed: {
    renderTreeView() {
      return this.glFeatures.k8sTreeView;
    },
    tabs() {
      return this.renderTreeView ? tabsWithSummary : defaultTabs;
    },
  },
  watch: {
    activeTabIndex(newValue) {
      this.$emit('input', this.tabs[newValue]);
    },
  },
};
</script>
<template>
  <div>
    <gl-tabs v-model="activeTabIndex">
      <kubernetes-summary
        v-if="renderTreeView"
        :flux-kustomization="fluxKustomization"
        :namespace="namespace"
        :configuration="configuration"
      />

      <kubernetes-pods
        :namespace="namespace"
        :configuration="configuration"
        @loading="$emit('loading', $event)"
        @update-failed-state="$emit('update-failed-state', $event)"
        @cluster-error="$emit('cluster-error', $event)"
        @select-item="$emit('select-item', $event)"
        @delete-pod="$emit('delete-pod', $event)"
      />

      <kubernetes-services
        :namespace="namespace"
        :configuration="configuration"
        @cluster-error="$emit('cluster-error', $event)"
        @select-item="$emit('select-item', $event)"
      />
    </gl-tabs>
  </div>
</template>
