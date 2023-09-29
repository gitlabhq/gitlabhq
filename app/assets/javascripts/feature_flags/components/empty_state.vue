<script>
import { GlAlert, GlEmptyState, GlLink, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: { GlAlert, GlEmptyState, GlLink, GlLoadingIcon },
  inject: ['errorStateSvgPath', 'featureFlagsHelpPagePath'],
  props: {
    count: {
      required: false,
      type: Number,
      default: null,
    },
    alerts: {
      required: true,
      type: Array,
    },
    isLoading: {
      required: true,
      type: Boolean,
    },
    loadingLabel: {
      required: true,
      type: String,
    },
    errorState: {
      required: true,
      type: Boolean,
    },
    errorTitle: {
      required: true,
      type: String,
    },
    emptyState: {
      required: true,
      type: Boolean,
    },
    emptyTitle: {
      required: true,
      type: String,
    },
    emptyDescription: {
      required: true,
      type: String,
    },
  },
  computed: {
    itemCount() {
      return this.count ?? 0;
    },
  },
  methods: {
    clearAlert(index) {
      this.$emit('dismissAlert', index);
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-for="(message, index) in alerts"
      :key="index"
      data-testid="serverErrors"
      variant="danger"
      @dismiss="clearAlert(index)"
    >
      {{ message }}
    </gl-alert>

    <gl-loading-icon v-if="isLoading" :label="loadingLabel" size="lg" class="gl-mt-4" />

    <gl-empty-state
      v-else-if="errorState"
      :title="errorTitle"
      :description="s__('FeatureFlags|Try again in a few moments or contact your support team.')"
      :svg-path="errorStateSvgPath"
      :svg-height="null"
      data-testid="error-state"
    />

    <gl-empty-state
      v-else-if="emptyState"
      :title="emptyTitle"
      :svg-path="errorStateSvgPath"
      :svg-height="150"
      data-testid="empty-state"
    >
      <template #description>
        {{ emptyDescription }}
        <gl-link :href="featureFlagsHelpPagePath" target="_blank">
          {{ s__('FeatureFlags|More information') }}
        </gl-link>
      </template>
    </gl-empty-state>
    <slot v-else> </slot>
  </div>
</template>
