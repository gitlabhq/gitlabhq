<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import { i18n, TRACKING_CATEGORY_SHOW, WIDGET_TYPE_ASSIGNEES } from '~/work_items/constants';
import Tracking from '~/tracking';
import { updateDraft, clearDraft } from '~/lib/utils/autosave';
import { renderMarkdown } from '~/notes/utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import EditedAt from '~/issues/show/components/edited.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateWorkItemNoteMutation from '../../graphql/notes/update_work_item_note.mutation.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  name: 'WorkItemNoteThread',
  components: {
    TimelineEntryItem,
    NoteBody,
    NoteHeader,
    NoteActions,
    GlAvatar,
    GlAvatarLink,
    WorkItemCommentForm,
    EditedAt,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
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
    assignees: {
      type: Array,
      required: false,
      default: () => [],
    },
    canSetWorkItemMetadata: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'work_item_note_actions',
        property: `type_${this.workItemType}`,
      };
    },
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
    isAuthorAnAssignee() {
      return Boolean(this.assignees.filter((assignee) => assignee.id === this.author.id).length);
    },
    currentUserId() {
      return window.gon.current_user_id;
    },
    canReportAbuse() {
      return getIdFromGraphQLId(this.author.id) !== this.currentUserId;
    },
  },
  apollo: {
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data.workspace?.workItems?.nodes[0];
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
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
      try {
        this.isEditing = false;
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
    getNewAssigneesAndWidget() {
      let newAssignees = [];
      if (this.isAuthorAnAssignee) {
        newAssignees = this.assignees.filter(({ id }) => id !== this.author.id);
      } else {
        newAssignees = [...this.assignees, this.author];
      }

      const isAssigneesWidget = (widget) => widget.type === WIDGET_TYPE_ASSIGNEES;

      const assigneesWidgetIndex = this.workItem.widgets.findIndex(isAssigneesWidget);

      const editedWorkItemWidgets = [...this.workItem.widgets];

      editedWorkItemWidgets[assigneesWidgetIndex] = {
        ...editedWorkItemWidgets[assigneesWidgetIndex],
        assignees: {
          nodes: newAssignees,
        },
      };

      return {
        newAssignees,
        editedWorkItemWidgets,
      };
    },
    notifyCopyDone() {
      if (this.isModal) {
        navigator.clipboard.writeText(this.noteUrl);
      }
      toast(__('Link copied to clipboard.'));
    },
    async assignUserAction() {
      const { newAssignees, editedWorkItemWidgets } = this.getNewAssigneesAndWidget();

      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              assigneesWidget: {
                assigneeIds: newAssignees.map(({ id }) => id),
              },
            },
          },
          optimisticResponse: {
            workItemUpdate: {
              errors: [],
              workItem: {
                ...this.workItem,
                widgets: editedWorkItemWidgets,
              },
            },
          },
        });
        this.track(`${this.isAuthorAnAssignee ? 'unassigned_user' : 'assigned_user'}`);
      } catch (error) {
        this.$emit('error', i18n.updateError);
        Sentry.captureException(error);
      }
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
        :comment-button-text="__('Save comment')"
        :autocomplete-data-sources="autocompleteDataSources"
        :markdown-preview-path="markdownPreviewPath"
        :work-item-id="workItemId"
        :autofocus="isEditing"
        class="gl-pl-3 gl-mt-3"
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
              :is-author-an-assignee="isAuthorAnAssignee"
              :show-assign-unassign="canSetWorkItemMetadata"
              :can-report-abuse="canReportAbuse"
              @startReplying="showReplyForm"
              @startEditing="startEditing"
              @error="($event) => $emit('error', $event)"
              @notifyCopyDone="notifyCopyDone"
              @deleteNote="$emit('deleteNote')"
              @assignUser="assignUserAction"
              @reportAbuse="$emit('reportAbuse')"
            />
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
