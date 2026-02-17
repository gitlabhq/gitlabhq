<script>
import { GlIcon, GlCard } from '@gitlab/ui';

export default {
  name: 'RepositoryHealthPerformanceCard',
  components: {
    GlIcon,
    GlCard,
  },
  props: {
    features: {
      type: Array,
      required: false,
      default: () => [],
    },
    headerText: {
      type: String,
      required: true,
    },
    footerText: {
      type: String,
      required: false,
      default: '',
    },
    noFeaturesText: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasFeatures() {
      return this.features.length;
    },
  },
  methods: {
    featureEnabledIcon(enabled) {
      return enabled
        ? { name: 'check-circle', class: 'gl-text-success' }
        : { name: 'canceled-circle', class: '' };
    },
  },
};
</script>

<template>
  <gl-card class="gl-bg-default">
    <p class="gl-text-sm gl-font-300" data-testid="performance-card-header">{{ headerText }}</p>

    <template v-if="hasFeatures">
      <p v-for="(feature, index) in features" :key="index" data-testid="performance-card-feature">
        <gl-icon
          :name="featureEnabledIcon(feature.enabled).name"
          :class="featureEnabledIcon(feature.enabled).class"
          class="gl-mr-3"
        />{{ feature.label }}
      </p>
      <p class="gl-mb-0 gl-text-sm gl-font-300" data-testid="performance-card-footer">
        {{ footerText }}
      </p>
    </template>
    <template v-else>
      <p class="gl-text-warning" data-testid="performance-card-no-features">
        {{ noFeaturesText }}
      </p>
    </template>
  </gl-card>
</template>
