<script>
  import { SCROLL_BAR_SIZE } from '../constants';

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
      };
    },
    computed: {
      tableStyles() {
        // return width after deducting size of vertical scrollbar
        // to hide the scrollbar while preserving ability to scroll
        return `width: ${this.shellWidth - SCROLL_BAR_SIZE}px;`;
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
          this.shellWidth = this.$el.parentElement.clientWidth;
        }
      });
    },
  };
</script>

<template>
  <table
    class="roadmap-shell"
    :style="tableStyles"
  >
    <roadmap-timeline-section
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
    />
    <epics-list-section
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
      :current-group-id="currentGroupId"
    />
  </table>
</template>
