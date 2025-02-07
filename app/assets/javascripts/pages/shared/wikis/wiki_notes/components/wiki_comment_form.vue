<script>
import { GlAlert, GlFormCheckbox, GlTooltipDirective, GlButton } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import CommentFieldLayout from '~/notes/components/comment_field_layout.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NOTE } from '~/graphql_shared/constants';
import createWikiPageNoteMuatation from '~/wikis/graphql/notes/create_wiki_page_note.mutation.graphql';
import updateWikiPageMutation from '~/wikis/graphql/notes/update_wiki_page_note.mutation.graphql';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { COMMENT_FORM } from '~/notes/i18n';
import { __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import * as constants from '~/notes/constants';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { createNoteErrorMessages, getAutosaveKey } from '../utils';
import WikiDiscussionLocked from './wiki_discussion_locked.vue';
import WikiDiscussionSignedOut from './wiki_discussions_signed_out.vue';

export default {
  name: 'WikiCommentForm',
  i18n: COMMENT_FORM,
  components: {
    GlAlert,
    GlFormCheckbox,
    WikiDiscussionSignedOut,
    WikiDiscussionLocked,
    TimelineEntryItem,
    CommentFieldLayout,
    MarkdownEditor,
    GlButton,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'pageInfo',
    'currentUserData',
    'markdownPreviewPath',
    'noteableType',
    'markdownDocsPath',
    'isContainerArchived',
  ],
  props: {
    noteableId: {
      type: String,
      required: true,
    },
    noteId: {
      type: String,
      required: true,
    },
    discussionId: {
      type: String,
      required: false,
      default: null,
    },
    isReply: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    canSetInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      errors: [],
      timeoutIds: [],
      note: '',
      noteType: constants.COMMENT,
      noteIsInternal: false,
      isSubmitting: false,
      formFieldProps: {
        id: 'wiki-comment-form',
        name: 'wiki-comment-form',
        'aria-label': __('Wiki comment form'),
        placeholder: __('Write a comment or drag your files here...'),
        'data-testid': 'note-textarea',
        class: 'note-textarea js-gfm-input js-autosize markdown-area',
      },
      noteableData: {
        discussion_locked: false,
        confidential: false,
        issue_email_participants: [],
        locked_discussion_docs_path: '',
        confidential_issues_docs_path: '',
      },
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl?.GfmAutoComplete?.dataSources;
    },
    userSignedId() {
      return Boolean(this.currentUserData?.id);
    },
    canCreateNote() {
      return !this.isContainerArchived;
    },
    autosaveKey() {
      if (this.userSignedId) {
        return getAutosaveKey(this.noteableType, this.noteId);
      }

      return '';
    },
    saveButtonTitle() {
      if (this.isReply) return __('Reply');
      if (this.isEdit) return __('Save comment');
      return __('Comment');
    },
    replyOrEdit() {
      return this.isReply || this.isEdit;
    },
    dynamicClasses() {
      return {
        formParent: {
          'timeline-content': !this.replyOrEdit,
        },
        root: {
          'gl-mt-6': this.replyOrEdit,
        },
      };
    },
  },
  beforeDestroy() {
    this.timeoutIds.forEach((id) => {
      clearTimeout(id);
    });
  },
  methods: {
    async handleCancel() {
      if (!this.note.trim()) {
        return this.$emit('cancel');
      }

      const msg = this.isEdit
        ? __('Are you sure you want to cancel editing this comment?')
        : __('Are you sure you want to cancel creating this comment?');

      const confirmed = await confirmAction(msg, {
        primaryBtnText: __('Discard changes'),
        cancelBtnText: this.isEdit ? __('Continue editing') : __('Continue creating'),
      });

      if (confirmed) {
        return this.$emit('cancel');
      }
      return null;
    },
    dismissError(index) {
      this.errors.splice(index, 1);
    },
    setError(err) {
      this.errors = err;
    },
    async handleSave() {
      this.errors = [];

      if (!this.note.trim()) return;
      this.isSubmitting = true;

      const confirmSubmit = await detectAndConfirmSensitiveTokens({ content: this.note });
      if (!confirmSubmit) {
        return;
      }

      const input = this.isEdit
        ? {
            id: convertToGraphQLId(TYPENAME_NOTE, this.noteId),
            body: this.note,
          }
        : {
            noteableId: this.noteableId,
            body: this.note,
            discussionId: this.isReply ? this.discussionId : null,
            internal: this.noteIsInternal,
          };

      this.$emit('creating-note:start', {
        ...input,
        individualNote: this.noteType === constants.DISCUSSION,
      });

      trackSavedUsingEditor(
        this.$refs.markdownEditor?.isContentEditorActive,
        `${this.noteableType}_${this.noteType}`,
      );

      this.note = '';

      try {
        const discussion = await this.$apollo.mutate({
          mutation: this.isEdit ? updateWikiPageMutation : createWikiPageNoteMuatation,
          variables: { input },
        });

        const response = this.isEdit
          ? discussion.data.updateNote?.note
          : discussion.data.createNote?.note?.discussion;

        this.$emit('creating-note:success', response);
      } catch (err) {
        this.setError(createNoteErrorMessages(err));
        this.$emit('creating-note:failed', err);
        this.note = input.body;

        this.timeoutIds.push(
          setTimeout(() => {
            this.$refs.markdownEditor.focus();
          }, 100),
        );
      } finally {
        this.isSubmitting = false;
        this.$emit('creating-note:done');
      }
    },
    onInput(value) {
      if (!this.isSubmitting) this.note = value;
    },
    disableSubmitButton() {
      return !this.note.trim() || this.isSubmitting;
    },
  },
};
</script>
<template>
  <div data-testid="wiki-note-comment-form-container" :class="dynamicClasses.root">
    <wiki-discussion-signed-out v-if="!userSignedId" />
    <wiki-discussion-locked v-else-if="!canCreateNote" />
    <ul
      v-else-if="canCreateNote"
      data-testid="wiki-note-comment-form"
      class="notes notes-form timeline"
    >
      <timeline-entry-item class="note-form">
        <gl-alert
          v-for="(error, index) in errors"
          :key="index"
          variant="danger"
          class="gl-mb-2"
          @dismiss="() => dismissError(index)"
        >
          {{ error }}
        </gl-alert>
        <div class="timeline-content-form" :class="dynamicClasses.formParent">
          <form
            ref="commentForm"
            class="new-note common-note-form gfm-form js-main-target-form"
            data-testid="wiki-note-form"
            @submit.stop.prevent
          >
            <comment-field-layout
              :with-alert-container="true"
              :is-internal-note="noteIsInternal"
              :note="note"
              :noteable-data="noteableData"
              :noteable-type="noteableType"
            >
              <markdown-editor
                ref="markdownEditor"
                :value="note"
                :autofocus="replyOrEdit"
                :render-markdown-path="markdownPreviewPath"
                :markdown-docs-path="markdownDocsPath"
                :add-spacing-classes="false"
                :form-field-props="formFieldProps"
                :autosave-key="autosaveKey"
                :disabled="isSubmitting"
                :autocomplete-data-sources="autocompleteDataSources"
                supports-quick-actions
                @keydown.shift.meta.enter="handleSave"
                @keydown.shift.ctrl.enter="handleSave"
                @keydown.meta.enter.exact="handleSave"
                @keydown.ctrl.enter.exact="handleSave"
                @input="onInput"
              />
            </comment-field-layout>
            <div v-if="replyOrEdit" class="gl-font-size-0 gl-mt-4 gl-flex gl-flex-wrap gl-gap-4">
              <gl-button
                :disabled="disableSubmitButton()"
                category="primary"
                variant="confirm"
                data-testid="wiki-note-save-button"
                class="js-vue-issue-save js-comment-button gl-w-full sm:gl-w-fit"
                @click="handleSave"
              >
                {{ saveButtonTitle }}
              </gl-button>
              <gl-button
                :disabled="isSubmitting"
                data-testid="wiki-note-cancel-button"
                class="note-edit-cancel js-close-discussion-note-form gl-w-full sm:gl-w-fit"
                category="secondary"
                variant="default"
                @click="handleCancel"
              >
                {{ __('Cancel') }}
              </gl-button>
            </div>
            <div v-else class="note-form-actions gl-font-size-0">
              <gl-form-checkbox
                v-if="canSetInternalNote"
                v-model="noteIsInternal"
                class="gl-mb-2 gl-basis-full"
                data-testid="wiki-internal-note-checkbox"
              >
                {{ $options.i18n.internal }}
                <help-icon
                  v-gl-tooltip:tooltipcontainer.bottom
                  :title="$options.i18n.internalVisibility"
                />
              </gl-form-checkbox>
              <gl-button
                :disabled="disableSubmitButton()"
                category="primary"
                variant="confirm"
                data-testid="wiki-note-comment-button"
                tracking-label="wiki-comment-button"
                class="js-vue-issue-save js-comment-button gl-mr-3 gl-w-full sm:gl-w-fit"
                @click="handleSave"
              >
                {{ saveButtonTitle }}
              </gl-button>
            </div>
          </form>
        </div>
      </timeline-entry-item>
    </ul>
  </div>
</template>
