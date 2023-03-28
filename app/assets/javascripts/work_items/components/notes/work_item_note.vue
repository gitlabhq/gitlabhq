<script>
import { GlAvatarLink, GlAvatar, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import { updateDraft, clearDraft } from '~/lib/utils/autosave';
import { renderMarkdown } from '~/notes/utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import EditedAt from '~/issues/show/components/edited.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import updateWorkItemNoteMutation from '../../graphql/notes/update_work_item_note.mutation.graphql';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  name: 'WorkItemNoteThread',
  i18n: {
    moreActionsText: __('More actions'),
    deleteNoteText: __('Delete comment'),
    copyLinkText: __('Copy link'),
  },
  components: {
    TimelineEntryItem,
    NoteBody,
    NoteHeader,
    NoteActions,
    GlAvatar,
    GlAvatarLink,
    GlDropdown,
    GlDropdownItem,
    WorkItemCommentForm,
    EditedAt,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    isFirstNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasReplies: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemType: {
      type: String,
      required: true,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isEditing: false,
      isSubmitting: false,
    };
  },
  computed: {
    author() {
      return this.note.author;
    },
    entryClass() {
      return {
        'note note-wrapper note-comment': true,
        target: this.isTarget,
        'inner-target': this.isTarget && !this.isFirstNote,
      };
    },
    showReply() {
      return this.note.userPermissions.createNote && this.isFirstNote;
    },
    noteHeaderClass() {
      return {
        'note-header': true,
      };
    },
    autosaveKey() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.note.id}-comment`;
    },
    lastEditedBy() {
      return this.note.lastEditedBy;
    },
    hasAdminPermission() {
      return this.note.userPermissions.adminNote;
    },
    noteAnchorId() {
      return `note_${getIdFromGraphQLId(this.note.id)}`;
    },
    isTarget() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    targetNoteHash() {
      return getLocationHash();
    },
    noteUrl() {
      return this.note.url;
    },
    hasAwardEmojiPermission() {
      return this.note.userPermissions.awardEmoji;
    },
  },
  methods: {
    showReplyForm() {
      this.$emit('startReplying');
    },
    startEditing() {
      this.isEditing = true;
      updateDraft(this.autosaveKey, this.note.body);
    },
    async updateNote(newText) {
      this.isSubmitting = true;
      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemNoteMutation,
          variables: {
            input: {
              id: this.note.id,
              body: newText,
            },
          },
          optimisticResponse: {
            updateNote: {
              errors: [],
              note: {
                ...this.note,
                bodyHtml: renderMarkdown(newText),
              },
            },
          },
        });
        /**
         * https://gitlab.com/gitlab-org/gitlab/-/issues/388314
         *
         * Once form is successfully submitted,
         * mark isSubmitting to false and clear storage before hiding the form.
         * This will restrict comment form to restore the value while textarea
         * input triggered due to keyboard event meta+enter.
         *
         */
        clearDraft(this.autosaveKey);
        this.isEditing = false;
      } catch (error) {
        updateDraft(this.autosaveKey, newText);
        this.isEditing = true;
        this.$emit('error', __('Something went wrong when updating a comment. Please try again'));
        Sentry.captureException(error);
      } finally {
        this.isSubmitting = false;
      }
    },
    notifyCopyDone() {
      if (this.isModal) {
        navigator.clipboard.writeText(this.noteUrl);
      }
      toast(__('Link copied to clipboard.'));
    },
  },
};
</script>

<template>
  <timeline-entry-item :id="noteAnchorId" :class="entryClass">
    <div :key="note.id" class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="author.webUrl">
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <div class="timeline-content">
      <work-item-comment-form
        v-if="isEditing"
        :work-item-type="workItemType"
        :aria-label="__('Edit comment')"
        :autosave-key="autosaveKey"
        :initial-value="note.body"
        :is-submitting="isSubmitting"
        :comment-button-text="__('Save comment')"
        :autocomplete-data-sources="autocompleteDataSources"
        :markdown-preview-path="markdownPreviewPath"
        @cancelEditing="isEditing = false"
        @submitForm="updateNote"
      />
      <div v-else data-testid="note-wrapper">
        <div :class="noteHeaderClass">
          <note-header
            :author="author"
            :created-at="note.createdAt"
            :note-id="note.id"
            :note-url="note.url"
          >
            <span v-if="note.createdAt" class="d-none d-sm-inline">&middot;</span>
          </note-header>
          <div class="gl-display-inline-flex">
            <note-actions
              :show-award-emoji="hasAwardEmojiPermission"
              :note-url="noteUrl"
              :show-reply="showReply"
              :show-edit="hasAdminPermission"
              :note-id="note.id"
              @startReplying="showReplyForm"
              @startEditing="startEditing"
              @error="($event) => $emit('error', $event)"
            />
            <gl-dropdown
              v-gl-tooltip
              icon="ellipsis_v"
              text-sr-only
              right
              :text="$options.i18n.moreActionsText"
              :title="$options.i18n.moreActionsText"
              category="tertiary"
              no-caret
            >
              <gl-dropdown-item :data-clipboard-text="noteUrl" @click="notifyCopyDone">
                <span>{{ $options.i18n.copyLinkText }}</span>
              </gl-dropdown-item>
              <gl-dropdown-item
                v-if="hasAdminPermission"
                variant="danger"
                data-testid="delete-note-action"
                @click="$emit('deleteNote')"
              >
                {{ $options.i18n.deleteNoteText }}
              </gl-dropdown-item>
            </gl-dropdown>
          </div>
        </div>
        <div class="timeline-discussion-body">
          <note-body ref="noteBody" :note="note" :has-replies="hasReplies" />
        </div>
        <edited-at
          v-if="note.lastEditedBy"
          :updated-at="note.lastEditedAt"
          :updated-by-name="lastEditedBy.name"
          :updated-by-path="lastEditedBy.webPath"
          :class="isFirstNote ? 'gl-pl-3' : 'gl-pl-8'"
        />
      </div>
    </div>
  </timeline-entry-item>
</template>
