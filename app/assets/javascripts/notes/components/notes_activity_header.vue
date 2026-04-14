<script>
import { DUO_CHAT_QUICK_ACTION_SUMMARIZE, DUO_CHAT_AGENT_PLANNER } from '~/ai/constants';
import { s__ } from '~/locale';
import glLicensedFeaturesMixin from '~/vue_shared/mixins/gl_licensed_features_mixin';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import DiscussionFilter from './discussion_filter.vue';

export default {
  name: 'NotesActivityHeader',
  components: {
    TimelineToggle: () => import('./timeline_toggle.vue'),
    DiscussionFilter,
    DuoChatQuickAction: () => import('ee_component/ai/shared/widgets/duo_chat_quick_action.vue'),
    MrDiscussionFilter: () => import('./mr_discussion_filter.vue'),
  },
  mixins: [glAbilitiesMixin(), glLicensedFeaturesMixin()],
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
    noteableType: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    summarizeTracking() {
      return { label: 'issue_view_summary', property: this.noteableType };
    },
    showAiActions() {
      return (
        this.resourceGlobalId &&
        this.glAbilities.summarizeComments &&
        this.glLicensedFeatures.summarizeComments
      );
    },
  },
  buttonOptions: { size: 'small' },
  classicQuickAction: DUO_CHAT_QUICK_ACTION_SUMMARIZE,
  summarizeCommand: {
    agent: { name: DUO_CHAT_AGENT_PLANNER },
    agenticPrompt: s__('AI|Summarize the comments on this issue.'),
  },
};
</script>

<template>
  <div
    class="gl-flex gl-flex-col gl-justify-between gl-pb-3 gl-pt-5 @sm/panel:gl-flex-row @sm/panel:gl-items-center"
  >
    <h2 class="gl-heading-2 gl-m-0">{{ __('Activity') }}</h2>
    <div class="gl-mt-3 gl-flex gl-w-full gl-gap-3 @sm/panel:gl-mt-0 @sm/panel:gl-w-auto">
      <duo-chat-quick-action
        v-if="showAiActions"
        :button-text="s__('AISummary|View summary')"
        :resource-id="resourceGlobalId"
        :tracking-info="summarizeTracking"
        :classic-quick-action="$options.classicQuickAction"
        :command="$options.summarizeCommand"
        :button-options="$options.buttonOptions"
      />
      <timeline-toggle v-if="showTimelineViewToggle" />
      <mr-discussion-filter v-if="mrFilter" />
      <discussion-filter v-else :filters="notesFilters" :selected-value="notesFilterValue" />
    </div>
  </div>
</template>
