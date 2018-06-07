<script>
  import eventHub from '../event_hub';

  import { PRESET_TYPES } from '../constants';

  import SectionMixin from '../mixins/section_mixin';

  import QuartersHeaderItem from './preset_quarters/quarters_header_item.vue';
  import MonthsHeaderItem from './preset_months/months_header_item.vue';
  import WeeksHeaderItem from './preset_weeks/weeks_header_item.vue';

  export default {
    components: {
      QuartersHeaderItem,
      MonthsHeaderItem,
      WeeksHeaderItem,
    },
    mixins: [
      SectionMixin,
    ],
    props: {
      presetType: {
        type: String,
        required: true,
      },
      epics: {
        type: Array,
        required: true,
      },
      timeframe: {
        type: Array,
        required: true,
      },
      shellWidth: {
        type: Number,
        required: true,
      },
      listScrollable: {
        type: Boolean,
        required: true,
      },
    },
    data() {
      return {
        scrolledHeaderClass: '',
      };
    },
    computed: {
      headerItemComponentForPreset() {
        if (this.presetType === PRESET_TYPES.QUARTERS) {
          return 'quarters-header-item';
        } else if (this.presetType === PRESET_TYPES.MONTHS) {
          return 'months-header-item';
        } else if (this.presetType === PRESET_TYPES.WEEKS) {
          return 'weeks-header-item';
        }
        return '';
      },
    },
    mounted() {
      eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
    },
    beforeDestroy() {
      eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
    },
    methods: {
      handleEpicsListScroll({ scrollTop }) {
        // Add class only when epics list is scrolled at 1% the height of header
        this.scrolledHeaderClass = (scrollTop > this.$el.clientHeight / 100) ? 'scroll-top-shadow' : '';
      },
    },
  };
</script>

<template>
  <div
    class="roadmap-timeline-section clearfix"
    :class="scrolledHeaderClass"
    :style="sectionContainerStyles"
  >
    <span class="timeline-header-blank"></span>
    <component
      :is="headerItemComponentForPreset"
      v-for="(timeframeItem, index) in timeframe"
      :key="index"
      :timeframe-index="index"
      :timeframe-item="timeframeItem"
      :timeframe="timeframe"
      :item-width="sectionItemWidth"
    />
  </div>
</template>
