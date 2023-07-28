<script>
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import TracingDetails from './components/tracing_details.vue';

export default {
  components: {
    ObservabilityContainer,
    TracingDetails,
  },
  props: {
    traceId: {
      type: String,
      required: true,
    },
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
    tracingIndexUrl: {
      required: true,
      type: String,
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
      <tracing-details
        :trace-id="traceId"
        :tracing-index-url="tracingIndexUrl"
        :observability-client="observabilityClient"
      />
    </template>
  </observability-container>
</template>
