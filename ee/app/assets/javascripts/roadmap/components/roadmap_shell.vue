<script>
  import bp from '~/breakpoints';
  import { SCROLL_BAR_SIZE, EPIC_ITEM_HEIGHT, SHELL_MIN_WIDTH } from '../constants';
  import eventHub from '../event_hub';

  import epicsListSection from './epics_list_section.vue';
  import roadmapTimelineSection from './roadmap_timeline_section.vue';

  export default {
    components: {
      epicsListSection,
      roadmapTimelineSection,
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
      currentGroupId: {
        type: Number,
        required: true,
      },
    },
    data() {
      return {
        shellWidth: 0,
        shellHeight: 0,
        noScroll: false,
      };
    },
    computed: {
      containerStyles() {
        const width = bp.windowWidth() > SHELL_MIN_WIDTH ?
          this.shellWidth + this.getWidthOffset() :
          this.shellWidth;

        return {
          width: `${width}px`,
          height: `${this.shellHeight}px`,
        };
      },
    },
    mounted() {
      this.$nextTick(() => {
        // Client width at the time of component mount will not
        // provide accurate size of viewport until child contents are
        // actually loaded and rendered into the DOM, hence
        // we wait for nextTick which ensures DOM update has completed
        // before setting shellWidth
        // see https://vuejs.org/v2/api/#Vue-nextTick
        if (this.$el.parentElement) {
          this.shellHeight = window.innerHeight - this.$el.offsetTop;
          this.noScroll = this.shellHeight > (EPIC_ITEM_HEIGHT * (this.epics.length + 1));
          this.shellWidth = this.$el.parentElement.clientWidth + this.getWidthOffset();
        }
      });
    },
    methods: {
      getWidthOffset() {
        return this.noScroll ? 0 : SCROLL_BAR_SIZE;
      },
      handleScroll() {
        const { scrollTop, scrollLeft, clientHeight, scrollHeight } = this.$el;
        if (!this.noScroll) {
          eventHub.$emit('epicsListScrolled', { scrollTop, scrollLeft, clientHeight, scrollHeight });
        }
      },
    },
  };
</script>

<template>
  <div
    class="roadmap-shell"
    :class="{ 'prevent-vertical-scroll': noScroll }"
    :style="containerStyles"
    @scroll="handleScroll"
  >
    <roadmap-timeline-section
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
      :list-scrollable="!noScroll"
    />
    <epics-list-section
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
      :current-group-id="currentGroupId"
      :list-scrollable="!noScroll"
    />
  </div>
</template>
