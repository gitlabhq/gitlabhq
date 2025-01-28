<script>
import { isEmpty } from 'lodash';
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { updateDraft, clearDraft } from '~/lib/utils/autosave';
import { renderMarkdown } from '~/notes/utils';
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import EditedAt from '~/issues/show/components/edited.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import { i18n, TRACKING_CATEGORY_SHOW } from '../../constants';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import updateWorkItemNoteMutation from '../../graphql/notes/update_work_item_note.mutation.graphql';
import workItemByIidQuery from '../../graphql/work_item_by_iid.query.graphql';
import { isAssigneesWidget } from '../../utils';
import WorkItemCommentForm from './work_item_comment_form.vue';
import NoteActions from './work_item_note_actions.vue';
import WorkItemNoteAwardsList from './work_item_note_awards_list.vue';
import NoteBody from './work_item_note_body.vue';

export default {
  name: 'WorkItemNoteThread',
  components: {
    WorkItemNoteAwardsList,
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
  props: {
    fullPath: {
      type: String,
      required: true,
    },
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
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
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
    isDiscussionResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDiscussionResolvable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
      workItem: {},
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
      return this.note.author || {};
    },
    hasAuthor() {
      return !isEmpty(this.author);
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    externalAuthor() {
      return this.note?.externalAuthor;
    },
    entryClass() {
      return {
        'note note-wrapper note-comment': true,
        target: this.isTarget,
        'inner-target': this.isTarget && !this.isFirstNote,
        'internal-note': this.note.internal,
      };
    },
    showReply() {
      return this.note.userPermissions.createNote && this.isFirstNote;
    },
    canResolve() {
      return this.note.userPermissions.resolveNote && this.isFirstNote && this.hasReplies;
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
      return getLocationHash() === this.noteAnchorId;
    },
    noteUrl() {
      const routeParamType = this.$route?.params?.type;
      if (routeParamType && !this.note.url.includes(routeParamType)) {
        return this.note.url.replace('work_items', routeParamType);
      }
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
    isCurrentUserAuthorOfNote() {
      return this.authorId === this.currentUserId;
    },
    isWorkItemAuthor() {
      return getIdFromGraphQLId(this.workItem.author?.id) === this.authorId;
    },
    projectName() {
      return this.workItem.namespace?.name;
    },
    isWorkItemConfidential() {
      return this.workItem.confidential;
    },
    discussionResolvedBy() {
      return this.note.discussion.resolvedBy;
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
        return data.workspace?.workItem ?? {};
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
      this.$emit('startEditing');
    },
    startEditing() {
      this.$emit('startEditing');
      this.isEditing = true;
      updateDraft(this.autosaveKey, this.note.body);
    },
    async updateNote({ commentText }) {
      try {
        this.isEditing = false;
        await this.$apollo.mutate({
          mutation: updateWorkItemNoteMutation,
          variables: {
            input: {
              id: this.note.id,
              body: commentText,
            },
          },
          optimisticResponse: {
            updateNote: {
              errors: [],
              note: {
                ...this.note,
                bodyHtml: renderMarkdown(commentText),
              },
            },
          },
        });
        clearDraft(this.autosaveKey);
      } catch (error) {
        updateDraft(this.autosaveKey, commentText);
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
    cancelEditing() {
      this.isEditing = false;
      this.$emit('cancelEditing');
    },
  },
};
</script>

<template>
  <timeline-entry-item :id="noteAnchorId" :class="entryClass">
    <div :key="note.id" class="timeline-avatar gl-float-left">
      <gl-avatar-link
        :href="author.webUrl"
        :data-user-id="authorId"
        :data-username="author.username"
        class="js-user-link"
      >
        <gl-avatar
          :src="author.avatarUrl"
          :entity-name="author.username"
          :alt="author.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <div class="timeline-content">
      <div data-testid="note-wrapper">
        <div :class="noteHeaderClass">
          <note-header
            :author="author"
            :created-at="note.createdAt"
            :note-id="note.id"
            :note-url="noteUrl"
            :is-internal-note="note.internal"
            :email-participant="externalAuthor"
          >
            <span v-if="note.createdAt" class="gl-hidden sm:gl-inline">&middot;</span>
          </note-header>
          <div class="gl-inline-flex">
            <note-actions
              v-if="!isEditing"
              :full-path="fullPath"
              :show-award-emoji="hasAwardEmojiPermission"
              :work-item-iid="workItemIid"
              :note="note"
              :note-url="noteUrl"
              :show-reply="showReply"
              :show-edit="hasAdminPermission"
              :note-id="note.id"
              :is-author-an-assignee="isAuthorAnAssignee"
              :show-assign-unassign="canSetWorkItemMetadata && hasAuthor"
              :can-report-abuse="!isCurrentUserAuthorOfNote"
              :is-work-item-author="isWorkItemAuthor"
              :work-item-type="workItemType"
              :is-author-contributor="note.authorIsContributor"
              :max-access-level-of-author="note.maxAccessLevelOfAuthor"
              :project-name="projectName"
              :can-resolve="canResolve"
              :resolvable="isDiscussionResolvable"
              :is-resolved="isDiscussionResolved"
              :is-resolving="isResolving"
              :resolved-by="discussionResolvedBy"
              @startReplying="showReplyForm"
              @startEditing="startEditing"
              @resolve="$emit('resolve')"
              @error="($event) => $emit('error', $event)"
              @notifyCopyDone="notifyCopyDone"
              @deleteNote="$emit('deleteNote')"
              @assignUser="assignUserAction"
              @reportAbuse="$emit('reportAbuse')"
            />
          </div>
        </div>
        <div class="note-body">
          <work-item-comment-form
            v-if="isEditing"
            :work-item-type="workItemType"
            :aria-label="__('Edit comment')"
            :autosave-key="autosaveKey"
            :initial-value="note.body"
            :comment-button-text="__('Save comment')"
            :autocomplete-data-sources="autocompleteDataSources"
            :markdown-preview-path="markdownPreviewPath"
            :new-comment-template-paths="newCommentTemplatePaths"
            :work-item-id="workItemId"
            :autofocus="isEditing"
            :is-work-item-confidential="isWorkItemConfidential"
            :is-discussion-resolved="isDiscussionResolved"
            :is-discussion-resolvable="isDiscussionResolvable"
            :has-replies="hasReplies"
            :full-path="fullPath"
            class="gl-mt-3"
            @cancelEditing="cancelEditing"
            @toggleResolveDiscussion="$emit('resolve')"
            @submitForm="updateNote"
          />
          <div v-else class="timeline-discussion-body">
            <note-body ref="noteBody" :note="note" :has-replies="hasReplies" />
          </div>
          <edited-at
            v-if="note.lastEditedBy && !isEditing"
            :updated-at="note.lastEditedAt"
            :updated-by-name="lastEditedBy.name"
            :updated-by-path="lastEditedBy.webPath"
            class="gl-mt-5"
            :class="isFirstNote ? '' : 'gl-pl-7'"
          />

          <div class="note-awards" :class="isFirstNote ? '' : 'gl-pl-7'">
            <work-item-note-awards-list
              :full-path="fullPath"
              :note="note"
              :work-item-iid="workItemIid"
              :is-modal="isModal"
            />
          </div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
