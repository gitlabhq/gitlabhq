<script>
import { colorFromDefaultPalette } from '@gitlab/ui/dist/utils/charts/theme';
import { roundOffFloat } from '~/lib/utils/common_utils';
import { formatNumber } from '~/locale';

export default {
  props: {
    /**
     * {
     *   id: string;
     *   label: string;
     *   value: number;
     *   formattedValue: number | string;
     *   color: string;
     *   hideLabel: boolean,
     * }[]
     */
    sections: {
      type: Array,
      required: true,
    },
  },
  computed: {
    sectionsCombinedValue() {
      return this.sections.reduce((accumulator, section) => {
        return accumulator + section.value;
      }, 0);
    },
    computedSections() {
      return this.sections.map((section, index) => {
        const percentage = section.value / this.sectionsCombinedValue;
        return {
          ...section,
          backgroundColor: section.color ?? colorFromDefaultPalette(index),
          cssPercentage: `${roundOffFloat(percentage * 100, 4)}%`,
          srLabelPercentage: formatNumber(percentage, {
            style: 'percent',
            minimumFractionDigits: 1,
          }),
        };
      });
    },
    sectionLabels() {
      return this.computedSections.filter((s) => !s.hideLabel);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-w-full gl-overflow-hidden gl-rounded-pill">
      <div
        v-for="{ id, label, backgroundColor, cssPercentage, srLabelPercentage } in computedSections"
        :key="id"
        class="gl-h-5"
        :style="{
          backgroundColor,
          width: cssPercentage,
        }"
        :data-testid="`percentage-bar-section-${id}`"
      >
        <span class="gl-sr-only">{{ label }} {{ srLabelPercentage }}</span>
      </div>
    </div>
    <div class="gl-mt-5">
      <div class="-gl-mx-3 -gl-my-3 gl-flex gl-flex-wrap gl-items-center">
        <div
          v-for="{ id, label, backgroundColor, formattedValue } in sectionLabels"
          :key="id"
          class="gl-flex gl-items-center gl-p-3"
          :data-testid="`percentage-bar-legend-section-${id}`"
        >
          <div
            class="gl-mr-2 gl-inline-block gl-h-2 gl-w-5"
            :style="{ backgroundColor }"
            data-testid="legend-section-color"
          ></div>
          <p class="gl-m-0 gl-text-sm">
            <span class="gl-mr-2 gl-font-bold">
              {{ label }}
            </span>
            <span class="gl-text-subtle">
              {{ formattedValue }}
            </span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
