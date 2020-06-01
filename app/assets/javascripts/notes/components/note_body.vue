<script>
import { mapActions, mapGetters } from 'vuex';
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';
import noteEditedText from './note_edited_text.vue';
import noteAwardsList from './note_awards_list.vue';
import noteAttachment from './note_attachment.vue';
import noteForm from './note_form.vue';
import autosave from '../mixins/autosave';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';

export default {
  components: {
    noteEditedText,
    noteAwardsList,
    noteAttachment,
    noteForm,
    Suggestions,
  },
  mixins: [autosave],
  props: {
    note: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters(['getDiscussion']),
    discussion() {
      if (!this.note.isDraft) return {};

      return this.getDiscussion(this.note.discussion_id);
    },
    noteBody() {
      return this.note.note;
    },
    hasSuggestion() {
      return this.note.suggestions && this.note.suggestions.length;
    },
    lineType() {
      return this.line ? this.line.type : null;
    },
  },
  mounted() {
    this.renderGFM();

    if (this.isEditing) {
      this.initAutoSave(this.note);
    }
  },
  updated() {
    this.renderGFM();

    if (this.isEditing) {
      if (!this.autosave) {
        this.initAutoSave(this.note);
      } else {
        this.setAutoSave();
      }
    }
  },
  methods: {
    ...mapActions(['submitSuggestion']),
    renderGFM() {
      $(this.$refs['note-body']).renderGFM();
    },
    handleFormUpdate(note, parentElement, callback, resolveDiscussion) {
      this.$emit('handleFormUpdate', note, parentElement, callback, resolveDiscussion);
    },
    formCancelHandler(shouldConfirm, isDirty) {
      this.$emit('cancelForm', shouldConfirm, isDirty);
    },
    applySuggestion({ suggestionId, flashContainer, callback = () => {} }) {
      const { discussion_id: discussionId, id: noteId } = this.note;

      return this.submitSuggestion({ discussionId, noteId, suggestionId, flashContainer }).then(
        callback,
      );
    },
  },
};
</script>

<template>
  <div ref="note-body" :class="{ 'js-task-list-container': canEdit }" class="note-body">
    <suggestions
      v-if="hasSuggestion && !isEditing"
      :suggestions="note.suggestions"
      :note-html="note.note_html"
      :line-type="lineType"
      :help-page-path="helpPagePath"
      @apply="applySuggestion"
    />
    <div v-else class="note-text md" v-html="note.note_html"></div>
    <note-form
      v-if="isEditing"
      ref="noteForm"
      :is-editing="isEditing"
      :note-body="noteBody"
      :note-id="note.id"
      :line="line"
      :note="note"
      :help-page-path="helpPagePath"
      :discussion="discussion"
      :resolve-discussion="note.resolve_discussion"
      @handleFormUpdate="handleFormUpdate"
      @cancelForm="formCancelHandler"
    />
    <textarea
      v-if="canEdit"
      v-model="note.note"
      :data-update-url="note.path"
      class="hidden js-task-list-field"
      dir="auto"
    ></textarea>
    <note-edited-text
      v-if="note.last_edited_at"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      action-text="Edited"
      class="note_edited_ago"
    />
    <note-awards-list
      v-if="note.award_emoji && note.award_emoji.length"
      :note-id="note.id"
      :note-author-id="note.author.id"
      :awards="note.award_emoji"
      :toggle-award-path="note.toggle_award_path"
      :can-award-emoji="note.current_user.can_award_emoji"
    />
    <note-attachment v-if="note.attachment" :attachment="note.attachment" />
  </div>
</template>
