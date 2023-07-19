<script>
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import TracingList from './components/tracing_list.vue';

export default {
  components: {
    ObservabilityContainer,
    TracingList,
  },
  props: {
    oauthUrl: {
      type: String,
      required: true,
    },
    tracingUrl: {
      type: String,
      required: true,
    },
    provisioningUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <observability-container
    :oauth-url="oauthUrl"
    :tracing-url="tracingUrl"
    :provisioning-url="provisioningUrl"
  >
    <template #default="{ observabilityClient }">
      <tracing-list :observability-client="observabilityClient" />
    </template>
  </observability-container>
</template>
