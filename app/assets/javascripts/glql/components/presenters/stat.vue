<script>
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { badgeVariantOptions } from '@gitlab/ui/src/utils/constants';
import iconSpriteInfo from '@gitlab/svgs/dist/icons.json';
import { __, sprintf } from '~/locale';
import { dimensionsOf, metricsOf } from '../../utils/chart_data';
import { valueFormatterFor } from '../../utils/value_format';
import { TREND_KEYS, statPresentationFor, trendPresentationFor } from './utils/stat';

// Rendered when an aggregated query has no row for the single metric. Aggregations
// over an empty set can omit the node entirely, so distinguish "no data" from a 0.
const NO_VALUE = '—';

const metricValueIn = (data, metric) => (metric ? data?.nodes?.[0]?.[metric.key] : undefined);

const BADGE_VARIANTS = Object.values(badgeVariantOptions);
const KNOWN_ICONS = new Set(iconSpriteInfo.icons);

export default {
  name: 'StatPresenter',
  components: {
    GlSingleStat,
    GlSkeletonLoader,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    comparisonData: {
      required: false,
      type: Object,
      default: null,
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
    displayConfig: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    source: {
      required: false,
      type: String,
      default: '',
    },
  },
  emits: { error: null },
  computed: {
    dimensions() {
      return dimensionsOf(this.fields);
    },
    metrics() {
      return metricsOf(this.fields);
    },
    statConfig() {
      return statPresentationFor(this.source, this.metric, {
        ...this.trend,
        ...this.displayConfig,
      });
    },
    // A block that sets any part of the badge owns all of it: its own text under a derived
    // arrow, colour and tooltip would make the badge contradict itself.
    trend() {
      if (TREND_KEYS.some((key) => this.displayConfig?.[key] != null)) return null;

      return trendPresentationFor(this.source, this.metric, {
        value: this.value,
        previousValue: this.previousValue,
      });
    },
    displayConfigError() {
      const { variant, metaIcon, titleIcon } = this.statConfig;

      if (!BADGE_VARIANTS.includes(variant)) {
        return sprintf(
          __('Unknown variant: `%{variant}`. Supported variants are: %{supportedVariants}.'),
          {
            variant,
            supportedVariants: BADGE_VARIANTS.map((option) => `\`${option}\``).join(', '),
          },
        );
      }

      const unknownIcon = Object.entries({ metaIcon, titleIcon }).find(
        ([, icon]) => icon !== null && !KNOWN_ICONS.has(icon),
      );
      if (unknownIcon) {
        const [key, icon] = unknownIcon;
        return sprintf(__('Unknown icon for `%{key}`: `%{icon}`.'), { key, icon });
      }

      return null;
    },
    validationError() {
      // Config errors do not depend on the query result, so they surface before it arrives.
      if (this.displayConfigError) return this.displayConfigError;
      if (!this.fields.length) return null;
      if (this.metrics.length !== 1) {
        return __('stat display type requires exactly 1 metric');
      }
      if (this.dimensions.length > 0) {
        return __('stat display type cannot have dimensions');
      }
      return null;
    },
    metric() {
      return this.metrics[0];
    },
    value() {
      return metricValueIn(this.data, this.metric);
    },
    previousValue() {
      return metricValueIn(this.comparisonData, this.metric);
    },
    displayValue() {
      if (!this.metric) return '';
      if (this.value == null) return NO_VALUE;
      return valueFormatterFor(this.metric)(this.value);
    },
  },
  watch: {
    validationError: {
      immediate: true,
      handler(message) {
        if (message) this.$emit('error', new Error(message));
      },
    },
  },
};
</script>

<template>
  <div>
    <gl-skeleton-loader v-if="loading" />
    <gl-single-stat
      v-else-if="!validationError && metric"
      class="!gl-p-0"
      :value="displayValue"
      :title="statConfig.title"
      :unit="statConfig.unit"
      :description="statConfig.description"
      :meta-text="statConfig.metaText"
      :meta-icon="statConfig.metaIcon"
      :meta-tooltip="statConfig.metaTooltip"
      :title-icon="statConfig.titleIcon"
      :variant="statConfig.variant"
    />
  </div>
</template>
