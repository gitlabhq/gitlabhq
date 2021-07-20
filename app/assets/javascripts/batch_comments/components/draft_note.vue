<script>
/* eslint-disable vue/no-v-html */
import { GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import NoteableNote from '~/notes/components/noteable_note.vue';
import PublishButton from './publish_button.vue';

export default {
  components: {
    NoteableNote,
    PublishButton,
    GlButton,
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
};
</script>
<template>
  <article
    class="draft-note-component note-wrapper"
    @mouseenter="handleMouseEnter(draft)"
    @mouseleave="handleMouseLeave(draft)"
  >
    <ul class="notes draft-notes">
      <noteable-note
        :note="draft"
        :line="line"
        :discussion-root="true"
        class="draft-note"
        @handleEdit="handleEditing"
        @cancelForm="handleNotEditing"
        @updateSuccess="handleNotEditing"
        @handleDeleteNote="deleteDraft"
        @handleUpdateNote="update"
        @toggleResolveStatus="toggleResolveDiscussion(draft.id)"
      >
        <template #note-header-info>
          <strong class="badge draft-pending-label gl-mr-2">
            {{ __('Pending') }}
          </strong>
        </template>
      </noteable-note>
    </ul>

    <template v-if="!isEditingDraft">
      <div
        v-if="draftCommands"
        class="referenced-commands draft-note-commands"
        v-html="draftCommands"
      ></div>

      <p class="draft-note-actions d-flex">
        <publish-button :show-count="true" :should-publish="false" category="secondary" />
        <gl-button
          ref="publishNowButton"
          :loading="isPublishingDraft(draft.id) || isPublishing"
          class="gl-ml-3"
          @click="publishNow"
        >
          {{ __('Add comment now') }}
        </gl-button>
      </p>
    </template>
  </article>
</template>
