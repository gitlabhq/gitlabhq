<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions as mapVuexActions } from 'vuex';
import { mapActions, mapState } from 'pinia';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NoteableNote from '~/notes/components/noteable_note.vue';
import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import { clearDraft } from '~/lib/utils/autosave';
import { useBatchComments } from '~/batch_comments/store';

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
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      // diff files in virtual scroller can be culled when scrolling the page (their instances get destroyed)
      // when a file reappears on the screen we need to restore draft's form: opened state and edited note text
      // we can detect if a file was culled with an opened form by saving the form opened state on the draft object
      // this can be used to force markdown editor to use autosaved content instead of an unedited draft note text
      // https://gitlab.com/gitlab-org/gitlab/-/issues/436954
      restoreFromAutosave: Boolean(this.draft.isEditing),
    };
  },
  computed: {
    ...mapState(useBatchComments, ['isPublishing', 'isPublishingDraft']),
    draftCommands() {
      return this.draft.references.commands;
    },
    autosaveDraftKey() {
      if (!this.autosaveKey) return null;
      return `${this.autosaveKey}/draft-note-${this.draft.id}`;
    },
  },
  mounted() {
    if (window.location.hash && window.location.hash === `#note_${this.draft.id}`) {
      this.scrollToDraft(this.draft);
    }
  },
  methods: {
    ...mapActions(useBatchComments, [
      'deleteDraft',
      'updateDraft',
      'publishSingleDraft',
      'scrollToDraft',
      'toggleResolveDiscussion',
    ]),
    ...mapActions(useBatchComments, {
      setDraftEditing: types.SET_DRAFT_EDITING,
    }),
    ...mapVuexActions(['setSelectedCommentPositionHover']),
    update(data) {
      this.updateDraft(data);
    },
    publishNow() {
      this.publishSingleDraft(this.draft.id);
    },
    handleEditing() {
      this.setDraftEditing({ draftId: this.draft.id, isEditing: true });
    },
    handleNotEditing() {
      this.restoreFromAutosave = false;
      this.clearDraft();
      this.setDraftEditing({ draftId: this.draft.id, isEditing: false });
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
    clearDraft() {
      if (this.autosaveDraftKey) clearDraft(this.autosaveDraftKey);
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
    class="draft-note !gl-mb-0"
    :autosave-key="autosaveDraftKey"
    :restore-from-autosave="restoreFromAutosave"
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
    <template v-if="!draft.isEditing" #after-note-body>
      <div
        v-if="draftCommands"
        v-safe-html:[$options.safeHtmlConfig]="draftCommands"
        class="draft-note-referenced-commands gl-mb-2 gl-ml-3 gl-text-sm gl-text-subtle"
      ></div>
    </template>
  </noteable-note>
</template>
