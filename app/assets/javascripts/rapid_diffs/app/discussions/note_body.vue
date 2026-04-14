<script>
import { gfm } from '~/vue_shared/directives/gfm';
import { __ } from '~/locale';
import NoteAttachment from '~/notes/components/note_attachment.vue';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import NoteForm from './note_form.vue';
import NoteSuggestions from './note_suggestions.vue';

export default {
  name: 'NoteBody',
  components: {
    AwardsList,
    NoteEditedText,
    NoteAttachment,
    NoteForm,
    NoteSuggestions,
  },
  directives: {
    gfm,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    saveNote: {
      type: Function,
      required: true,
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
    autosaveKey: {
      type: String,
      required: false,
      default: '',
    },
    restoreFromAutosave: {
      type: Boolean,
      required: false,
      default: false,
    },
    saveNoteErrorMessages: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    noteBody: {
      get() {
        return this.note.editedNote ?? this.note.note;
      },
      set(value) {
        this.$emit('input', value);
      },
    },
    saveButtonTitle() {
      return this.note.internal ? __('Save internal note') : __('Save comment');
    },
    currentUserId() {
      return window.gon?.current_user_id;
    },
    hasSuggestion() {
      return this.note.suggestions?.length > 0;
    },
  },
};
</script>

<template>
  <div :class="{ 'js-task-list-container': canEdit }">
    <div class="flash-container !gl-mt-0 gl-mb-3 !gl-px-0"></div>
    <note-suggestions v-if="hasSuggestion && !isEditing" :note="note" />
    <div
      v-else
      v-gfm="note.note_html"
      :class="{ '[content-visibility:hidden]': isEditing }"
      class="md"
    ></div>
    <note-form
      v-if="isEditing"
      :note-body="noteBody"
      :note-id="note.id"
      :save-button-title="saveButtonTitle"
      :autosave-key="autosaveKey"
      :restore-from-autosave="restoreFromAutosave"
      :save-note="saveNote"
      :save-note-error-messages="saveNoteErrorMessages"
      @input="$emit('input', $event)"
      @cancel="$emit('cancelEditing', $event)"
    />
    <textarea
      v-if="canEdit"
      v-model="noteBody"
      :data-update-url="note.path"
      class="js-task-list-field gl-hidden"
      dir="auto"
    ></textarea>
    <note-edited-text
      v-if="note.last_edited_at && note.last_edited_at !== note.created_at"
      :edited-at="note.last_edited_at"
      :edited-by="note.last_edited_by"
      :action-text="__('Edited')"
      class="gl-mt-2"
    />
    <div v-if="note.award_emoji && note.award_emoji.length" class="gl-mt-3">
      <awards-list
        :awards="note.award_emoji"
        :can-award-emoji="note.current_user.can_award_emoji"
        :current-user-id="currentUserId"
        @award="$emit('award', $event)"
      />
    </div>
    <note-attachment v-if="note.attachment" :attachment="note.attachment" />
  </div>
</template>
