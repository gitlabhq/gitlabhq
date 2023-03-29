<script>
import DiscussionFilter from './discussion_filter.vue';

export default {
  components: {
    TimelineToggle: () => import('./timeline_toggle.vue'),
    DiscussionFilter,
  },
  inject: {
    showTimelineViewToggle: {
      default: false,
    },
  },
  props: {
    notesFilters: {
      type: Array,
      required: true,
    },
    notesFilterValue: {
      type: Number,
      default: undefined,
      required: false,
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-sm-align-items-center gl-flex-direction-column gl-sm-flex-direction-row gl-justify-content-space-between gl-pt-5 gl-pb-3"
  >
    <h2 class="gl-font-size-h1 gl-m-0">{{ __('Activity') }}</h2>
    <div class="gl-display-flex gl-gap-3 gl-w-full gl-sm-w-auto gl-mt-3 gl-sm-mt-0">
      <timeline-toggle v-if="showTimelineViewToggle" />
      <discussion-filter :filters="notesFilters" :selected-value="notesFilterValue" />
    </div>
  </div>
</template>
