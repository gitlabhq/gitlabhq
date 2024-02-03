<script>
import { GlTabs } from '@gitlab/ui';
import KubernetesPods from './kubernetes_pods.vue';
import KubernetesServices from './kubernetes_services.vue';

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
  },
};
</script>
<template>
  <gl-tabs>
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
