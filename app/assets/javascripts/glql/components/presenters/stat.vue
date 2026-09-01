<script>
import { GlSingleStat } from '@gitlab/ui/src/charts';
import { GlSkeletonLoader } from '@gitlab/ui';
import { badgeVariantOptions } from '@gitlab/ui/src/utils/constants';
import iconSpriteInfo from '@gitlab/svgs/dist/icons.json';
import { __, sprintf } from '~/locale';
import { baseFieldKeyOf, dimensionsOf, metricsOf } from '../../utils/chart_data';
import { formatterFor } from '../../utils/value_format';

// Rendered when an aggregated query has no row for the single metric. Aggregations
// over an empty set can omit the node entirely, so distinguish "no data" from a 0.
const NO_VALUE = '—';

const BADGE_VARIANTS = Object.values(badgeVariantOptions);
const KNOWN_ICONS = new Set(iconSpriteInfo.icons);

// `displayConfig` comes from user-authored YAML, so a scalar can arrive as a number or a
// boolean. GlSingleStat's props are strings and would log a type warning without this.
const asString = (value) => (value == null ? null : String(value));

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
      const config = this.displayConfig ?? {};
      const metaText = asString(config.metaText);

      return {
        // A block's own `title:` and a dashboard panel each render a heading already, so the
        // stat's title stays empty unless a block asks for one. Every other key defaults to
        // the GlSingleStat default, keeping a config-free stat rendering as it does today.
        title: asString(config.title) ?? '',
        unit: asString(config.unit),
        description: asString(config.description),
        metaText,
        metaIcon: asString(config.metaIcon),
        // The tooltip hangs off the meta badge, which GlSingleStat only renders with `metaText`.
        metaTooltip: metaText ? (asString(config.metaTooltip) ?? '') : '',
        titleIcon: asString(config.titleIcon),
        variant: asString(config.variant) ?? badgeVariantOptions.neutral,
      };
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
    displayValue() {
      if (!this.metric) return '';
      const value = this.data?.nodes?.[0]?.[this.metric.key];
      if (value == null) return NO_VALUE;
      return formatterFor(baseFieldKeyOf(this.metric))(value);
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
