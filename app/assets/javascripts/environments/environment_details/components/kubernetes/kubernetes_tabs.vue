<script>
import { GlTabs } from '@gitlab/ui';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesServices from './kubernetes_services.vue';

const tabs = [k8sResourceType.k8sPods, k8sResourceType.k8sServices];

export default {
  components: {
    GlTabs,
    KubernetesPods,
    KubernetesServices,
  },

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
  },
  data() {
    return {
      activeTabIndex: tabs.indexOf(this.value),
    };
  },
  watch: {
    activeTabIndex(newValue) {
      this.$emit('input', tabs[newValue]);
    },
  },
};
</script>
<template>
  <gl-tabs v-model="activeTabIndex">
    <kubernetes-pods
      :namespace="namespace"
      :configuration="configuration"
      @loading="$emit('loading', $event)"
      @update-failed-state="$emit('update-failed-state', $event)"
      @cluster-error="$emit('cluster-error', $event)"
    />

    <kubernetes-services
      :namespace="namespace"
      :configuration="configuration"
      @cluster-error="$emit('cluster-error', $event)"
    />
  </gl-tabs>
</template>
