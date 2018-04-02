<script>
  import eventHub from '../event_hub';

  import SectionMixin from '../mixins/section_mixin';

  import timelineHeaderItem from './timeline_header_item.vue';

  export default {
    components: {
      timelineHeaderItem,
    },
    mixins: [
      SectionMixin,
    ],
    props: {
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
    <timeline-header-item
      v-for="(timeframeItem, index) in timeframe"
      :key="index"
      :timeframe-index="index"
      :timeframe-item="timeframeItem"
      :timeframe="timeframe"
      :item-width="sectionItemWidth"
    />
  </div>
</template>
