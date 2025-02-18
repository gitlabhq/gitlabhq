<script>
import { GlModal } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __ } from '~/locale';
import {
  TYPENAME_DISCUSSION,
  TYPENAME_DISCUSSION_NOTE,
  TYPENAME_NOTE,
} from '~/graphql_shared/constants';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import {
  i18n,
  DEFAULT_PAGE_SIZE_NOTES,
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
  NEW_WORK_ITEM_IID,
} from '~/work_items/constants';
import { ASC, DESC } from '~/notes/constants';
import { autocompleteDataSources, markdownPreviewPath } from '~/work_items/utils';
import {
  updateCacheAfterCreatingNote,
  updateCacheAfterDeletingNote,
} from '~/work_items/graphql/cache_utils';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';
import { getLocationHash } from '~/lib/utils/url_utility';
import { collapseSystemNotes } from '~/work_items/notes/collapse_utils';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import WorkItemHistoryOnlyFilterNote from '~/work_items/components/notes/work_item_history_only_filter_note.vue';
import workItemNoteCreatedSubscription from '~/work_items/graphql/notes/work_item_note_created.subscription.graphql';
import workItemNoteUpdatedSubscription from '~/work_items/graphql/notes/work_item_note_updated.subscription.graphql';
import workItemNoteDeletedSubscription from '~/work_items/graphql/notes/work_item_note_deleted.subscription.graphql';
import deleteNoteMutation from '../graphql/notes/delete_work_item_notes.mutation.graphql';
import workItemNoteQuery from '../graphql/notes/work_item_note.query.graphql';
import workItemNotesByIidQuery from '../graphql/notes/work_item_notes_by_iid.query.graphql';
import WorkItemAddNote from './notes/work_item_add_note.vue';

export default {
  components: {
    GlModal,
    SystemNote,
    WorkItemAddNote,
    WorkItemDiscussion,
    WorkItemNotesActivityHeader,
    WorkItemHistoryOnlyFilterNote,
    WorkItemNotesLoading,
  },
  inject: ['isGroup'],
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
    workItemType: {
      type: String,
      required: true,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
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
    reportAbusePath: {
      type: String,
      required: true,
    },
    isDiscussionLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    isWorkItemConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    useH2: {
      type: Boolean,
      default: false,
      required: false,
    },
    parentId: {
      type: String,
      default: null,
      required: false,
    },
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
    smallHeaderStyle: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      isLoadingMore: false,
      sortOrder: ASC,
      noteToDelete: null,
      discussionFilter: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
      workItemNamespace: null,
      previewNote: null,
    };
  },
  computed: {
    initialLoading() {
      return this.$apollo.queries.workItemNotes.loading && !this.isLoadingMore;
    },
    someNotesLoaded() {
      return !this.initialLoading || this.previewNote;
    },
    avatarUrl() {
      return window.gon.current_user_avatar_url;
    },
    pageInfo() {
      return this.workItemNotes?.pageInfo;
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
    disableActivityFilterSort() {
      return this.initialLoading || this.isLoadingMore;
    },
    formAtTop() {
      return this.sortOrder === DESC;
    },
    markdownPreviewPath() {
      const { fullPath, workItemIid: iid } = this;
      return markdownPreviewPath({ fullPath, iid, isGroup: this.isGroupWorkItem });
    },
    isGroupWorkItem() {
      return this.workItemNamespace?.id?.includes?.('Group');
    },
    autocompleteDataSources() {
      const { fullPath, workItemIid: iid } = this;
      const isNewWorkItemInGroup = this.isGroup && iid === NEW_WORK_ITEM_IID;
      return autocompleteDataSources({
        fullPath,
        iid,
        isGroup: this.isGroupWorkItem || isNewWorkItemInGroup,
      });
    },
    workItemCommentFormProps() {
      return {
        fullPath: this.fullPath,
        workItemId: this.workItemId,
        workItemIid: this.workItemIid,
        workItemType: this.workItemType,
        sortOrder: this.sortOrder,
        isNewDiscussion: true,
        markdownPreviewPath: this.markdownPreviewPath,
        newCommentTemplatePaths: this.newCommentTemplatePaths,
        autocompleteDataSources: this.autocompleteDataSources,
        isDiscussionLocked: this.isDiscussionLocked,
        isWorkItemConfidential: this.isWorkItemConfidential,
        parentId: this.parentId,
      };
    },
    notesArray() {
      const notes = this.workItemNotes?.nodes || [];

      let visibleNotes = collapseSystemNotes(notes);

      visibleNotes = visibleNotes.filter((note) => {
        const isSystemNote = this.isSystemNote(note);

        if (this.discussionFilter === WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS && isSystemNote) {
          return false;
        }

        if (this.discussionFilter === WORK_ITEM_NOTES_FILTER_ONLY_HISTORY && !isSystemNote) {
          return false;
        }

        return true;
      });

      // don't show preview in modal, as we might accidentally load a note from the parent work item
      const urlParams = new URLSearchParams(window.location.search);
      const modalOpen = urlParams.has('show');

      if (this.previewNote && !this.previewNoteLoadedInList && !modalOpen) {
        visibleNotes = [...visibleNotes, this.previewNote];
      }

      if (this.sortOrder === DESC) {
        return [...visibleNotes].reverse();
      }

      return visibleNotes;
    },
    commentsDisabled() {
      return this.discussionFilter === WORK_ITEM_NOTES_FILTER_ONLY_HISTORY;
    },
    targetNoteHash() {
      return getLocationHash();
    },
    previewNoteId() {
      const hash = this.targetNoteHash;
      const isSha = /^note_([a-f0-9]{40})/.test(hash); // synthetic note id
      const isNoteId = /^note_(\d+)/.test(hash);

      if (isSha || !isNoteId) {
        return null;
      }

      return hash.replace(/^note_/, '');
    },
    previewNoteLoadedInList() {
      // are these the same? could there be ID conflicts when they aren't? test data was using DiscussionNote
      const noteId = convertToGraphQLId(TYPENAME_NOTE, this.previewNoteId);
      const discussionNoteId = convertToGraphQLId(TYPENAME_DISCUSSION_NOTE, this.previewNoteId);

      function matchingNoteId(note) {
        return note.notes.nodes.find((singleReply) => {
          return singleReply.id === noteId || singleReply.id === discussionNoteId;
        });
      }

      const notes = this.workItemNotes?.nodes || [];
      const n = notes.find(matchingNoteId);
      return Boolean(n);
    },
  },
  mounted() {
    if (this.targetNoteHash) {
      this.cleanup = scrollToTargetOnResize();
    }
  },
  apollo: {
    previewNote: {
      skip() {
        return !this.previewNoteId;
      },
      query: workItemNoteQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_NOTE, this.previewNoteId),
        };
      },
      update(data) {
        return data?.note?.discussion;
      },
      result(result) {
        if (result?.errors?.length > 0) {
          Sentry.captureException(result.errors[0].message);
        }

        // make sure skeleton notes are placed below the preview note
        if (result?.data?.note && this.$apollo.queries.workItemNotes?.loading) {
          this.isLoadingMore = true;
        } else {
          this.cleanup?.();
        }
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    workItemNotes: {
      query: workItemNotesByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
          after: this.after,
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
        };
      },
      update(data) {
        const widgets = data.workspace?.workItem?.widgets;
        return widgets?.find((widget) => widget.type === 'NOTES')?.discussions || [];
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      result({ data }) {
        this.workItemNamespace = data.workspace?.workItem?.namespace;
        this.isLoadingMore = false;
        if (this.hasNextPage) {
          this.fetchMoreNotes();
        }
      },
      subscribeToMore: [
        {
          document: workItemNoteCreatedSubscription,
          updateQuery(previousResult, { subscriptionData: { data } }) {
            return updateCacheAfterCreatingNote(previousResult, data?.workItemNoteCreated);
          },
          variables() {
            return {
              noteableId: this.workItemId,
            };
          },
          skip() {
            return !this.workItemId || this.hasNextPage;
          },
        },
        {
          document: workItemNoteDeletedSubscription,
          updateQuery(previousResult, { subscriptionData }) {
            return updateCacheAfterDeletingNote(previousResult, subscriptionData);
          },
          variables() {
            return {
              noteableId: this.workItemId,
            };
          },
          skip() {
            return !this.workItemId || this.hasNextPage;
          },
        },
        {
          document: workItemNoteUpdatedSubscription,
          variables() {
            return {
              noteableId: this.workItemId,
            };
          },
          skip() {
            return !this.workItemId;
          },
        },
      ],
    },
  },
  methods: {
    getDiscussionKey(discussion) {
      // discussion key is important like this since after first comment changes
      const discussionId = discussion.notes.nodes[0].id;
      return discussionId.split('/')[discussionId.split('/').length - 1];
    },
    isSystemNote(note) {
      return note.notes.nodes[0].system;
    },
    changeNotesSortOrder(direction) {
      this.sortOrder = direction;
    },
    filterDiscussions(filterValue) {
      this.discussionFilter = filterValue;
    },
    reportAbuse(isOpen, reply = {}) {
      this.$emit('openReportAbuse', reply);
    },
    noteId(note) {
      return getIdFromGraphQLId(note.id);
    },
    isHashTargeted(discussion) {
      return (
        discussion.notes.nodes.length &&
        discussion.notes.nodes.some((note) => this.targetNoteHash === `note_${this.noteId(note)}`)
      );
    },
    isDiscussionExpandedOnLoad(discussion) {
      return !this.isDiscussionResolved(discussion) || this.isHashTargeted(discussion);
    },
    isDiscussionResolved(discussion) {
      return discussion.notes.nodes[0]?.discussion?.resolved;
    },
    async fetchMoreNotes() {
      this.isLoadingMore = true;
      await this.$apollo.queries.workItemNotes
        .fetchMore({
          variables: {
            fullPath: this.fullPath,
            iid: this.workItemIid,
            after: this.pageInfo?.endCursor,
          },
        })
        .catch((error) => this.$emit('error', error.message));
    },
    showDeleteNoteModal(note, discussion) {
      const isLastNote = discussion.notes.nodes.length === 1;
      this.$refs.deleteNoteModal.show();
      this.noteToDelete = { ...note, isLastNote };
    },
    cancelDeletingNote() {
      this.noteToDelete = null;
    },
    async deleteNote() {
      try {
        const { id, isLastNote, discussion } = this.noteToDelete;
        await this.$apollo.mutate({
          mutation: deleteNoteMutation,
          variables: {
            input: {
              id,
            },
          },
          update(cache) {
            const deletedObject = isLastNote
              ? { __typename: TYPENAME_DISCUSSION, id: discussion.id }
              : { __typename: TYPENAME_NOTE, id };
            cache.modify({
              id: cache.identify(deletedObject),
              fields: (_, { DELETE }) => DELETE,
            });
          },
          optimisticResponse: {
            destroyNote: {
              note: null,
              __typename: 'DestroyNotePayload',
            },
          },
        });
      } catch (error) {
        this.$emit('error', __('Something went wrong when deleting a comment. Please try again'));
        Sentry.captureException(error);
      }
    },
  },
};
</script>

<template>
  <div class="work-item-notes">
    <work-item-notes-activity-header
      :sort-order="sortOrder"
      :disable-activity-filter-sort="disableActivityFilterSort"
      :work-item-type="workItemType"
      :discussion-filter="discussionFilter"
      :use-h2="useH2"
      :small-header-style="smallHeaderStyle"
      @changeSort="changeNotesSortOrder"
      @changeFilter="filterDiscussions"
    />
    <work-item-notes-loading v-if="initialLoading" class="gl-mt-5" />
    <div v-if="someNotesLoaded" class="issuable-discussion gl-mb-5 !gl-clearfix">
      <div v-if="formAtTop && !commentsDisabled" class="js-comment-form">
        <ul class="notes notes-form timeline">
          <work-item-add-note
            v-bind="workItemCommentFormProps"
            @startEditing="$emit('startEditing')"
            @stopEditing="$emit('stopEditing')"
            @error="$emit('error', $event)"
          />
        </ul>
      </div>
      <work-item-notes-loading v-if="formAtTop && isLoadingMore" />
      <ul class="notes main-notes-list timeline">
        <template v-for="discussion in notesArray">
          <system-note
            v-if="isSystemNote(discussion)"
            :key="discussion.notes.nodes[0].id"
            :note="discussion.notes.nodes[0]"
          />
          <template v-else>
            <work-item-discussion
              :key="getDiscussionKey(discussion)"
              :discussion="discussion.notes.nodes"
              :full-path="fullPath"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="workItemType"
              :is-modal="isModal"
              :autocomplete-data-sources="autocompleteDataSources"
              :markdown-preview-path="markdownPreviewPath"
              :new-comment-template-paths="newCommentTemplatePaths"
              :assignees="assignees"
              :can-set-work-item-metadata="canSetWorkItemMetadata"
              :is-discussion-locked="isDiscussionLocked"
              :is-work-item-confidential="isWorkItemConfidential"
              :is-expanded-on-load="isDiscussionExpandedOnLoad(discussion)"
              @deleteNote="showDeleteNoteModal($event, discussion)"
              @reportAbuse="reportAbuse(true, $event)"
              @error="$emit('error', $event)"
              @startEditing="$emit('startEditing')"
              @cancelEditing="$emit('stopEditing')"
            />
          </template>
        </template>

        <work-item-history-only-filter-note
          v-if="commentsDisabled"
          @changeFilter="filterDiscussions"
        />
      </ul>
      <work-item-notes-loading v-if="!formAtTop && isLoadingMore" />
      <div v-if="!formAtTop && !commentsDisabled" class="js-comment-form">
        <ul class="notes notes-form timeline">
          <work-item-add-note
            v-bind="workItemCommentFormProps"
            @startEditing="$emit('startEditing')"
            @stopEditing="$emit('stopEditing')"
            @error="$emit('error', $event)"
          />
        </ul>
      </div>
    </div>
    <gl-modal
      ref="deleteNoteModal"
      modal-id="delete-note-modal"
      :title="__('Delete comment?')"
      :ok-title="__('Delete comment')"
      ok-variant="danger"
      size="sm"
      @primary="deleteNote"
      @canceled="cancelDeletingNote"
    >
      {{ __('Are you sure you want to delete this comment?') }}
    </gl-modal>
  </div>
</template>
