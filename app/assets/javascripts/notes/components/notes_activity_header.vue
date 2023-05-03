<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DiscussionFilter from './discussion_filter.vue';

export default {
  components: {
    TimelineToggle: () => import('./timeline_toggle.vue'),
    DiscussionFilter,
    AiSummarizeNotes: () =>
      import('ee_component/notes/components/note_actions/ai_summarize_notes.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    showTimelineViewToggle: {
      default: false,
    },
    resourceGlobalId: { default: null },
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
    aiLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    showAiActions() {
      return this.resourceGlobalId && this.glFeatures.summarizeComments;
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
      <ai-summarize-notes
        v-if="showAiActions"
        :resource-global-id="resourceGlobalId"
        :loading="aiLoading"
      />
      <timeline-toggle v-if="showTimelineViewToggle" />
      <discussion-filter :filters="notesFilters" :selected-value="notesFilterValue" />
    </div>
  </div>
</template>
