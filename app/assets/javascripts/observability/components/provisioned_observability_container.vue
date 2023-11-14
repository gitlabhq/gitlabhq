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
    apiConfig: {
      type: Object,
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
          message: s__('Observability|Error: Failed to load page. Try reloading the page.'),
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
          message: s__(
            'Observability|Error: Failed to enable GitLab Observability. Please retry later.',
          ),
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
    :api-config="apiConfig"
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
