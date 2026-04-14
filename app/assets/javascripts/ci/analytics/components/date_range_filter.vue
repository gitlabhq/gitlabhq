<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

import { calculateDatesFromRelativeDays } from '../utils';

import {
  DATE_RANGE_7_DAYS,
  DATE_RANGE_30_DAYS,
  DATE_RANGE_90_DAYS,
  DATE_RANGE_180_DAYS,
  DATE_RANGE_DEFAULT,
  DATE_RANGES_AS_DAYS,
} from '../constants';

const DATE_RANGES = [
  { key: DATE_RANGE_7_DAYS, days: 7, text: s__('PipelineCharts|Last week') },
  { key: DATE_RANGE_30_DAYS, days: 30, text: s__('PipelineCharts|Last 30 days') },
  { key: DATE_RANGE_90_DAYS, days: 90, text: s__('PipelineCharts|Last 90 days') },
  { key: DATE_RANGE_180_DAYS, days: 180, text: s__('PipelineCharts|Last 180 days') },
];

export default {
  name: 'DateRangeFilter',
  components: {
    GlFormGroup,
    GlCollapsibleListbox,
  },
  model: {
    prop: 'selected',
    event: 'select',
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['select'],
  data() {
    return {
      dateRange: null,
    };
  },
  computed: {
    items() {
      return DATE_RANGES.map(({ key, text }) => ({
        value: key,
        text,
      }));
    },
    formattedRange() {
      const { fromTime, toTime } = calculateDatesFromRelativeDays(
        DATE_RANGES_AS_DAYS[this.dateRange] || 7,
      );

      return localeDateFormat.asDate.formatRange(fromTime, toTime);
    },
  },
  watch: {
    selected: {
      handler(key) {
        // We may receive an invalid key from the URL, check if it is a valid option or set the default
        this.dateRange = DATE_RANGES.find((r) => r.key === key)?.key || DATE_RANGE_DEFAULT;
      },
      immediate: true,
    },
  },
  methods: {
    onSelect(dateRange) {
      this.dateRange = dateRange;

      this.$emit('select', dateRange);
    },
  },
};
</script>

<template>
  <gl-form-group
    class="gl-min-w-full @sm/panel:gl-min-w-15"
    :label="__('Date range')"
    :label-for="id"
  >
    <div :class="{ 'gl-w-full': block }" class="gl-block gl-gap-3 @sm/panel:gl-flex">
      <gl-collapsible-listbox
        :id="id"
        class="gl-grow"
        :selected="dateRange"
        :block="block"
        :items="items"
        @select="onSelect"
      />
      <div class="gl-self-end gl-py-2 gl-text-sm gl-text-subtle">{{ formattedRange }}</div>
    </div>
  </gl-form-group>
</template>
