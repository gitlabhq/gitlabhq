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
          backgroundColor: colorFromDefaultPalette(index),
          cssPercentage: `${roundOffFloat(percentage * 100, 4)}%`,
          srLabelPercentage: formatNumber(percentage, {
            style: 'percent',
            minimumFractionDigits: 1,
          }),
        };
      });
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-rounded-pill gl-overflow-hidden gl-w-full">
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
      <div class="gl-display-flex gl-align-items-center gl-flex-wrap -gl-my-3 -gl-mx-3">
        <div
          v-for="{ id, label, backgroundColor, formattedValue } in computedSections"
          :key="id"
          class="gl-display-flex gl-align-items-center gl-p-3"
          :data-testid="`percentage-bar-legend-section-${id}`"
        >
          <div
            class="gl-h-2 gl-w-5 gl-mr-2 gl-display-inline-block"
            :style="{ backgroundColor }"
            data-testid="legend-section-color"
          ></div>
          <p class="gl-m-0 gl-font-sm">
            <span class="gl-mr-2 gl-font-bold">
              {{ label }}
            </span>
            <span class="gl-text-gray-500">
              {{ formattedValue }}
            </span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
