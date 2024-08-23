<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import DiscussionFilter from './discussion_filter.vue';

export default {
  components: {
    TimelineToggle: () => import('./timeline_toggle.vue'),
    DiscussionFilter,
    AiSummarizeNotes: () =>
      import('ee_component/notes/components/note_actions/ai_summarize_notes.vue'),
    MrDiscussionFilter: () => import('./mr_discussion_filter.vue'),
  },
  mixins: [glAbilitiesMixin(), glFeatureFlagsMixin()],
  inject: {
    showTimelineViewToggle: {
      default: false,
    },
    resourceGlobalId: { default: null },
    mrFilter: {
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
    aiLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    showAiActions() {
      return (
        this.resourceGlobalId &&
        this.glAbilities.summarizeComments &&
        this.glFeatures.summarizeComments
      );
    },
  },
};
</script>

<template>
  <div
    class="gl-flex gl-flex-col gl-justify-between gl-pb-3 gl-pt-5 sm:gl-flex-row sm:gl-items-center"
  >
    <h2 class="gl-m-0 gl-text-size-h1">{{ __('Activity') }}</h2>
    <div class="gl-mt-3 gl-flex gl-w-full gl-gap-3 sm:gl-mt-0 sm:gl-w-auto">
      <ai-summarize-notes
        v-if="showAiActions"
        :resource-global-id="resourceGlobalId"
        :loading="aiLoading"
      />
      <timeline-toggle v-if="showTimelineViewToggle" />
      <mr-discussion-filter v-if="mrFilter" />
      <discussion-filter v-else :filters="notesFilters" :selected-value="notesFilterValue" />
    </div>
  </div>
</template>
