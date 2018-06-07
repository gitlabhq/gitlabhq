<script>
  import { monthInWords } from '~/lib/utils/datetime_utility';

  import { PRESET_TYPES } from '../../constants';

  import timelineTodayIndicator from '../timeline_today_indicator.vue';

  export default {
    presetType: PRESET_TYPES.QUARTERS,
    components: {
      timelineTodayIndicator,
    },
    props: {
      currentDate: {
        type: Date,
        required: true,
      },
      timeframeItem: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        quarterBeginDate: this.timeframeItem.range[0],
        quarterEndDate: this.timeframeItem.range[2],
      };
    },
    computed: {
      headerSubItems() {
        return this.timeframeItem.range;
      },
      hasToday() {
        return this.currentDate >= this.quarterBeginDate &&
               this.currentDate <= this.quarterEndDate;
      },
    },
    methods: {
      getSubItemValueClass(subItem) {
        let itemValueClass = '';

        if (this.currentDate.getFullYear() === subItem.getFullYear() &&
            this.currentDate.getMonth() === subItem.getMonth()) {
          itemValueClass = 'label-dark label-bold';
        } else if (this.currentDate < subItem) {
          itemValueClass = 'label-dark';
        }
        return itemValueClass;
      },
      getSubItemValue(subItem) {
        return monthInWords(subItem, true);
      },
    },
  };
</script>

<template>
  <div class="item-sublabel">
    <span
      v-for="(subItem, index) in headerSubItems"
      :key="index"
      class="sublabel-value"
      :class="getSubItemValueClass(subItem)"
    >
      {{ getSubItemValue(subItem) }}
    </span>
    <timeline-today-indicator
      v-if="hasToday"
      :preset-type="$options.presetType"
      :current-date="currentDate"
      :timeframe-item="timeframeItem"
    />
  </div>
</template>
