<script>
import { GlAlert, GlBadge, GlEmptyState, GlLink, GlLoadingIcon, GlTab } from '@gitlab/ui';

export default {
  components: { GlAlert, GlBadge, GlEmptyState, GlLink, GlLoadingIcon, GlTab },
  props: {
    title: {
      required: true,
      type: String,
    },
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
  },
  inject: ['errorStateSvgPath', 'featureFlagsHelpPagePath'],
  computed: {
    itemCount() {
      return this.count ?? 0;
    },
  },
  methods: {
    clearAlert(index) {
      this.$emit('dismissAlert', index);
    },
    onClick(event) {
      return this.$emit('changeTab', event);
    },
  },
};
</script>
<template>
  <gl-tab @click="onClick">
    <template #title>
      <span data-testid="feature-flags-tab-title">{{ title }}</span>
      <gl-badge size="sm" class="gl-tab-counter-badge">{{ itemCount }}</gl-badge>
    </template>
    <template>
      <gl-alert
        v-for="(message, index) in alerts"
        :key="index"
        data-testid="serverErrors"
        variant="danger"
        @dismiss="clearAlert(index)"
      >
        {{ message }}
      </gl-alert>

      <gl-loading-icon v-if="isLoading" :label="loadingLabel" size="md" class="gl-mt-4" />

      <gl-empty-state
        v-else-if="errorState"
        :title="errorTitle"
        :description="s__(`FeatureFlags|Try again in a few moments or contact your support team.`)"
        :svg-path="errorStateSvgPath"
        data-testid="error-state"
      />

      <gl-empty-state
        v-else-if="emptyState"
        :title="emptyTitle"
        :svg-path="errorStateSvgPath"
        data-testid="empty-state"
      >
        <template #description>
          {{
            s__(
              'FeatureFlags|Feature flags allow you to configure your code into different flavors by dynamically toggling certain functionality.',
            )
          }}
          <gl-link :href="featureFlagsHelpPagePath" target="_blank">
            {{ s__('FeatureFlags|More information') }}
          </gl-link>
        </template>
      </gl-empty-state>
      <slot> </slot>
    </template>
  </gl-tab>
</template>
