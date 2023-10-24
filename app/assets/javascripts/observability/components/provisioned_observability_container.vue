<script>
import { GlLoadingIcon } from '@gitlab/ui';
import ObservabilityContainer from '~/observability/components/observability_container.vue';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import ObservabilityEmptyState from './observability_empty_state.vue';

export default {
  components: {
    ObservabilityContainer,
    ObservabilityEmptyState,
    GlLoadingIcon,
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
    servicesUrl: {
      type: String,
      required: true,
    },
    provisioningUrl: {
      type: String,
      required: true,
    },
    operationsUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      /**
       * observabilityEnabled: boolean | null.
       * null identifies a state where we don't know if observability is enabled or not (e.g. when fetching the status from the API fails)
       */
      observabilityEnabled: null,
      observabilityClient: null,
    };
  },
  computed: {
    isObservabilityStatusKnown() {
      return this.observabilityEnabled !== null;
    },
    isObservabilityDisabled() {
      return this.observabilityEnabled === false;
    },
    isObservabilityEnabled() {
      return this.observabilityEnabled;
    },
  },
  methods: {
    onObservabilityClientReady(client) {
      this.observabilityClient = client;
      this.checkEnabled();
    },
    async checkEnabled() {
      this.loading = true;
      try {
        this.observabilityEnabled = await this.observabilityClient.isObservabilityEnabled();
      } catch (e) {
        createAlert({
          message: s__('Observability|Failed to load page.'),
        });
      } finally {
        this.loading = false;
      }
    },
    async onEnableObservability() {
      this.loading = true;
      try {
        await this.observabilityClient.enableObservability();
        this.observabilityEnabled = true;
      } catch (e) {
        createAlert({
          message: s__('Observability|Failed to enable GitLab Observability.'),
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <observability-container
    :oauth-url="oauthUrl"
    :tracing-url="tracingUrl"
    :provisioning-url="provisioningUrl"
    :services-url="servicesUrl"
    :operations-url="operationsUrl"
    @observability-client-ready="onObservabilityClientReady"
  >
    <div v-if="loading" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <template v-else-if="isObservabilityStatusKnown">
      <observability-empty-state
        v-if="isObservabilityDisabled"
        @enable-observability="onEnableObservability"
      />
      <slot v-if="isObservabilityEnabled" :observability-client="observabilityClient"></slot>
    </template>
  </observability-container>
</template>
