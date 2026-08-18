<script>
import { gfm } from '~/vue_shared/directives/gfm';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, sprintf } from '~/locale';
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
    SafeHtml,
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
    isFirstNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['award', 'cancel-editing', 'input'],
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
    isDuoFirstReviewComment() {
      if (this.note.author.user_type !== 'duo_code_review_bot') {
        return false;
      }

      return this.isFirstNote;
    },
    duoFeedbackText() {
      return sprintf(
        __(
          'Rate this response %{emoji} %{separator} Mention %{codeStart}%{botUser}%{codeEnd} to continue the conversation.',
        ),
        {
          separator: '•',
          codeStart: '<code>',
          botUser: `@${this.note.author.username}`,
          codeEnd: '</code>',
          emoji:
            '<gl-emoji data-name="thumbsup"></gl-emoji> <gl-emoji data-name="thumbsdown"></gl-emoji>',
        },
        false,
      );
    },
    defaultAwardsList() {
      return this.isDuoFirstReviewComment ? ['thumbsup', 'thumbsdown'] : [];
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
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
      @cancel="$emit('cancel-editing', $event)"
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
    <div
      v-if="isDuoFirstReviewComment"
      v-safe-html:[$options.safeHtmlConfig]="duoFeedbackText"
      class="gl-mt-4 gl-text-md gl-text-subtle"
      data-testid="duo-review-feedback"
    ></div>
    <div
      v-if="defaultAwardsList.length || (note.award_emoji && note.award_emoji.length)"
      class="gl-mt-3"
    >
      <awards-list
        :awards="note.award_emoji"
        :can-award-emoji="note.current_user.can_award_emoji"
        :current-user-id="currentUserId"
        :default-awards="defaultAwardsList"
        @award="$emit('award', $event)"
      />
    </div>
    <note-attachment v-if="note.attachment" :attachment="note.attachment" />
  </div>
</template>
