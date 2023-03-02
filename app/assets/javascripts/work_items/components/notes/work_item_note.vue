<script>
import { GlAvatarLink, GlAvatar, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { __ } from '~/locale';
import { updateDraft, clearDraft } from '~/lib/utils/autosave';
import { renderMarkdown } from '~/notes/utils';
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
  },
  data() {
    return {
      isEditing: false,
    };
  },
  computed: {
    author() {
      return this.note.author;
    },
    entryClass() {
      return {
        'note note-wrapper note-comment gl-mb-4': true,
        'gl-p-2 gl-mt-3 gl-pl-3': !this.isFirstNote,
      };
    },
    showReply() {
      return this.note.userPermissions.createNote && this.isFirstNote;
    },
    noteHeaderClass() {
      return {
        'note-header': true,
        'gl-pt-2': !this.isFirstNote,
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
      this.isEditing = false;
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
        clearDraft(this.autosaveKey);
      } catch (error) {
        updateDraft(this.autosaveKey, newText);
        this.isEditing = true;
        this.$emit('error', __('Something went wrong when updating a comment. Please try again'));
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <timeline-entry-item :class="entryClass">
    <div v-if="!isFirstNote" :key="note.id" class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="author.webUrl">
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <work-item-comment-form
      v-if="isEditing"
      :work-item-type="workItemType"
      :aria-label="__('Edit comment')"
      :autosave-key="autosaveKey"
      :initial-value="note.body"
      :comment-button-text="__('Save comment')"
      :class="{ 'gl-pl-8': !isFirstNote }"
      @cancelEditing="isEditing = false"
      @submitForm="updateNote"
    />
    <div v-else class="timeline-content-inner" data-testid="note-wrapper">
      <div :class="noteHeaderClass">
        <note-header :author="author" :created-at="note.createdAt" :note-id="note.id">
          <span v-if="note.createdAt" class="d-none d-sm-inline">&middot;</span>
        </note-header>
        <div class="gl-display-inline-flex">
          <note-actions
            :show-reply="showReply"
            :show-edit="hasAdminPermission"
            @startReplying="showReplyForm"
            @startEditing="startEditing"
          />
          <!-- v-if condition should be moved to "delete" dropdown item as soon as we implement copying the link -->
          <gl-dropdown
            v-if="hasAdminPermission"
            v-gl-tooltip
            icon="ellipsis_v"
            text-sr-only
            right
            :text="$options.i18n.moreActionsText"
            :title="$options.i18n.moreActionsText"
            category="tertiary"
            no-caret
          >
            <gl-dropdown-item
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
  </timeline-entry-item>
</template>
