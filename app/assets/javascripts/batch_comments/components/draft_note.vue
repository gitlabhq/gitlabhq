<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NoteableNote from '~/notes/components/noteable_note.vue';

export default {
  components: {
    NoteableNote,
    GlBadge,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    draft: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isEditingDraft: false,
    };
  },
  computed: {
    ...mapState('batchComments', ['isPublishing']),
    ...mapGetters('batchComments', ['isPublishingDraft']),
    draftCommands() {
      return this.draft.references.commands;
    },
  },
  mounted() {
    if (window.location.hash && window.location.hash === `#note_${this.draft.id}`) {
      this.scrollToDraft(this.draft);
    }
  },
  methods: {
    ...mapActions('batchComments', [
      'deleteDraft',
      'updateDraft',
      'publishSingleDraft',
      'scrollToDraft',
      'toggleResolveDiscussion',
    ]),
    ...mapActions(['setSelectedCommentPositionHover']),
    update(data) {
      this.updateDraft(data);
    },
    publishNow() {
      this.publishSingleDraft(this.draft.id);
    },
    handleEditing() {
      this.isEditingDraft = true;
    },
    handleNotEditing() {
      this.isEditingDraft = false;
    },
    handleMouseEnter(draft) {
      if (draft.position) {
        this.setSelectedCommentPositionHover(draft.position.line_range);
      }
    },
    handleMouseLeave(draft) {
      // Even though position isn't used here we still don't want to unnecessarily call a mutation
      // The lack of position tells us that highlighting is irrelevant in this context
      if (draft.position) {
        this.setSelectedCommentPositionHover();
      }
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>
<template>
  <noteable-note
    :note="draft"
    :line="line"
    :discussion-root="true"
    class="draft-note-component draft-note !gl-mb-0"
    @handleEdit="handleEditing"
    @cancelForm="handleNotEditing"
    @updateSuccess="handleNotEditing"
    @handleDeleteNote="deleteDraft"
    @handleUpdateNote="update"
    @toggleResolveStatus="toggleResolveDiscussion(draft.id)"
    @mouseenter.native="handleMouseEnter(draft)"
    @mouseleave.native="handleMouseLeave(draft)"
  >
    <template #note-header-info>
      <gl-badge
        v-gl-tooltip
        variant="warning"
        class="gl-mr-2"
        :title="__('Pending comments are hidden until you submit your review.')"
      >
        {{ __('Pending') }}
      </gl-badge>
    </template>
    <template v-if="!isEditingDraft" #after-note-body>
      <div
        v-if="draftCommands"
        v-safe-html:[$options.safeHtmlConfig]="draftCommands"
        class="referenced-commands draft-note-commands"
      ></div>
    </template>
  </noteable-note>
</template>
