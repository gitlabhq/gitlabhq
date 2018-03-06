<script>
  import eventHub from '../event_hub';

  import { SCROLL_BAR_SIZE } from '../constants';

  import timelineHeaderItem from './timeline_header_item.vue';

  export default {
    components: {
      timelineHeaderItem,
    },
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
    },
    data() {
      return {
        scrolledHeaderClass: '',
      };
    },
    computed: {
      calcShellWidth() {
        return this.shellWidth - SCROLL_BAR_SIZE;
      },
      theadStyles() {
        return `width: ${this.calcShellWidth}px;`;
      },
    },
    mounted() {
      eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
    },
    beforeDestroy() {
      eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
    },
    methods: {
      handleEpicsListScroll(scrollTop) {
        // Add class only when epics list is scrolled at 1% the height of header
        this.scrolledHeaderClass = (scrollTop > this.$el.clientHeight / 100) ? 'scrolled-ahead' : '';
      },
    },
  };
</script>

<template>
  <thead
    class="roadmap-timeline-section"
    :class="scrolledHeaderClass"
    :style="theadStyles"
  >
    <tr>
      <th class="timeline-header-blank"></th>
      <timeline-header-item
        v-for="(timeframeItem, index) in timeframe"
        :key="index"
        :timeframe-index="index"
        :timeframe-item="timeframeItem"
        :timeframe="timeframe"
        :shell-width="calcShellWidth"
      />
    </tr>
  </thead>
</template>
