<script>
import { cloneDeep } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import { __ } from '~/locale';
import { getDraft } from '~/lib/utils/autosave';
import { getAutosaveKey, getIdFromGid } from '../utils';
import WikiCommentForm from './wiki_comment_form.vue';

export default {
  name: 'NoteBody',
  directives: {
    SafeHtml,
  },
  components: {
    NoteEditedText,
    WikiCommentForm,
  },
  inject: ['noteableType'],
  props: {
    note: {
      type: Object,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      updatedNote: cloneDeep(this.note),
    };
  },
  computed: {
    edited() {
      const { createdAt, lastEditedAt } = this.updatedNote;

      return new Date(createdAt).getTime() !== new Date(lastEditedAt).getTime();
    },
    editedText() {
      return __('Edited');
    },
    noteId() {
      return getIdFromGid(this.note?.id);
    },
    hasDraft() {
      return getDraft(this.autosaveKey)?.trim();
    },
    autosaveKey() {
      return getAutosaveKey(this.noteableType, this.noteId);
    },
  },
  watch: {
    isEditing(newVal) {
      if (Boolean(newVal) && !this.hasDraft) {
        this.$nextTick(() => {
          this.$refs.commentForm.note = this.updatedNote.body;
        });
      }
    },
  },
  methods: {
    updateNote(newNote) {
      this.updatedNote = newNote;
      this.$emit('creating-note:success');
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
};
</script>
<template>
  <div>
    <div
      ref="note-body"
      :class="{
        'js-task-list-container': canEdit,
      }"
      class="note-body"
    >
      <template v-if="!isEditing">
        <div
          v-safe-html:[$options.safeHtmlConfig]="updatedNote.bodyHtml"
          data-testid="wiki-note-content"
          class="note-text md"
        ></div>

        <note-edited-text
          v-if="edited"
          :edited-at="updatedNote.lastEditedAt"
          :action-text="editedText"
          class-name="gl-text-subtle gl-text-sm gl-display-block gl-mt-4"
        />
      </template>

      <div v-if="isEditing" class="note-edit-form current-note-edit-form js-discussion-note-form">
        <wiki-comment-form
          ref="commentForm"
          is-edit
          :note-id="noteId"
          :noteable-id="noteableId"
          :discussion-id="note.discussion.id"
          @cancel="$emit('cancel:edit')"
          @creating-note:start="$emit('creating-note:start')"
          @creating-note:success="updateNote"
          @creating-note:done="$emit('creating-note:done')"
        />
      </div>
    </div>
  </div>
</template>
