<script>
import { GlModal } from '@gitlab/ui';
import { isEmpty } from 'lodash';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __ } from '~/locale';
import {
  TYPENAME_DISCUSSION,
  TYPENAME_DISCUSSION_NOTE,
  TYPENAME_NOTE,
  TYPENAME_USER,
} from '~/graphql_shared/constants';
import { Mousetrap } from '~/lib/mousetrap';
import { ISSUABLE_COMMENT_OR_REPLY, keysFor } from '~/behaviors/shortcuts/keybindings';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import gfmEventHub from '~/vue_shared/components/markdown/eventhub';
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import {
  i18n,
  DEFAULT_PAGE_SIZE_NOTES,
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
  NEW_WORK_ITEM_IID,
} from '~/work_items/constants';
import { ASC, DESC, DISCUSSIONS_SORT_ENUM } from '~/notes/constants';
import { autocompleteDataSources, findNotesWidget } from '~/work_items/utils';
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
import namespacePathsQuery from '~/work_items/graphql/namespace_paths.query.graphql';
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
    workItemTypeId: {
      type: String,
      required: false,
      default: '',
    },
    isDrawer: {
      type: Boolean,
      required: false,
      default: false,
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
    canSummarizeComments: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateNote: {
      type: Boolean,
      required: false,
      default: false,
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
    hideFullscreenMarkdownButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoadingMore: false,
      initialSortOrder: localStorage.getItem(WORK_ITEM_NOTES_SORT_ORDER_KEY) || ASC,
      sortOrder: ASC,
      noteToDelete: null,
      discussionFilter: WORK_ITEM_NOTES_FILTER_ALL_NOTES,
      markdownPaths: {},
      workItemNamespace: null,
      previewNote: null,
      workItemNotes: [],
      notesCached: null,
    };
  },
  computed: {
    shouldLoadPreviewNote() {
      return this.previewNoteId && !this.isDrawer && !this.isModal;
    },
    initialLoading() {
      return this.$apollo.queries.workItemNotes.loading && !this.isLoadingMore;
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
    markdownPathsLoaded() {
      return !isEmpty(this.markdownPaths);
    },
    markdownPreviewPath() {
      return this.markdownPaths.markdownPreviewPath;
    },
    uploadsPath() {
      return this.markdownPaths.uploadsPath;
    },
    autocompleteDataSources() {
      return autocompleteDataSources(this.markdownPaths.autocompleteSourcesPath);
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
    // On the first component load, we want to show per-page skeleton notes
    // On any subsequent refetch, we want to show the cached notes until all notes are loaded
    notesSource() {
      return this.notesCached ?? this.workItemNotes;
    },
    notesArray() {
      const notes = this.notesSource.nodes || [];

      let visibleNotes = collapseSystemNotes(notes, this.initialSortOrder);

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

      if (this.sortOrder !== this.initialSortOrder) {
        return [...visibleNotes].reverse();
      }

      return visibleNotes;
    },
    userComments() {
      return this.notesArray
        .flatMap((discussion) => discussion.notes.nodes)
        .filter((note) => !note.system);
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

      const notes = this.notesSource?.nodes || [];
      const n = notes.find(matchingNoteId);
      return Boolean(n);
    },
  },
  mounted() {
    if (this.shouldLoadPreviewNote) {
      this.cleanupScrollListener = scrollToTargetOnResize();
    }
    if (this.canCreateNote) {
      Mousetrap.bind(keysFor(ISSUABLE_COMMENT_OR_REPLY), (e) => this.quoteReply(e));
      gfmEventHub.$on('edit-current-user-last-note', this.editCurrentUserLastNote);
    }
  },
  beforeDestroy() {
    if (this.canCreateNote) {
      Mousetrap.unbind(keysFor(ISSUABLE_COMMENT_OR_REPLY), this.quoteReply);
      gfmEventHub.$off('edit-current-user-last-note', this.editCurrentUserLastNote);
    }
  },
  apollo: {
    previewNote: {
      skip() {
        return !this.shouldLoadPreviewNote;
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
        }
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    workItemNotes: {
      query: workItemNotesByIidQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
          after: this.after,
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
          sort: DISCUSSIONS_SORT_ENUM[this.initialSortOrder],
        };
      },
      update(data) {
        return findNotesWidget(data.workspace?.workItem)?.discussions || [];
      },
      skip() {
        return !this.workItemIid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      result({ data }) {
        this.workItemNamespace = data?.workspace?.workItem?.namespace;
        this.isLoadingMore = false;
        if (this.hasNextPage) {
          this.fetchMoreNotes();
        } else {
          this.cleanupScrollListener?.();
          this.notesCached = this.workItemNotes;
        }
      },
      subscribeToMore: [
        {
          document: workItemNoteCreatedSubscription,
          updateQuery(previousResult, { subscriptionData: { data } }) {
            return updateCacheAfterCreatingNote(previousResult, data?.workItemNoteCreated, {
              prepend: this.initialSortOrder === DESC,
            });
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
    markdownPaths: {
      query: namespacePathsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iidForAutocompleteSources: this.workItemIid,
          iidForMarkdownPreview:
            this.workItemIid === NEW_WORK_ITEM_IID ? undefined : this.workItemIid,
          workItemTypeId: this.workItemTypeId,
        };
      },
      update(data) {
        return data?.namespace?.markdownPaths || {};
      },
      skip() {
        return !this.fullPath || !this.workItemIid || !this.workItemTypeId;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  methods: {
    editCurrentUserLastNote(e) {
      const currentUserId = convertToGraphQLId(TYPENAME_USER, gon.current_user_id);
      const isToplevelCommentForm = Boolean(e.target.closest('.js-comment-form'));
      let availableNotes = [];

      if (isToplevelCommentForm) {
        // User hit `Up` key from top-level comment form, populate all the comments,
        // also ensure to reverse them only if sort order is set to newest-first (DESC).
        availableNotes = this.formAtTop ? [...this.userComments] : [...this.userComments].reverse();
      } else {
        // User hit `Up` key from a comment form within an existing thread, populate
        // all the comments, from this thread, and reverse order so the latest comments come first.
        const discussionId = convertToGraphQLId(
          TYPENAME_DISCUSSION_NOTE,
          e.target.closest('.js-timeline-entry').dataset.discussionId,
        );
        availableNotes = [
          ...this.notesArray.find((discussion) => discussion.id === discussionId).notes.nodes,
        ].reverse();
      }

      // Find current user's last note.
      const currentUserLastNote = availableNotes.find((note) => note.author.id === currentUserId);

      if (!currentUserLastNote) return;

      gfmEventHub.$emit('edit-note', {
        note: currentUserLastNote,
      });
    },
    getDiscussionIdFromSelection() {
      const selection = window.getSelection();
      if (selection.rangeCount <= 0) return null;

      // Return early if selection is from description, we need to use the top-level comment field.
      if (selection.anchorNode?.parentElement?.closest('.js-work-item-description')) return null;

      const el = selection.getRangeAt(0).startContainer;
      const node = el.nodeType === Node.TEXT_NODE ? el.parentNode : el;
      return node.closest('.js-timeline-entry').getAttribute('discussion-id');
    },
    async quoteReply(e) {
      const discussionId = this.getDiscussionIdFromSelection();
      const text = await CopyAsGFM.selectionToGfm();

      // Prevent 'r' being written.
      if (e && typeof e.preventDefault === 'function') {
        e.preventDefault();
      }

      // Check if selection is coming from an existing discussion
      if (discussionId) {
        gfmEventHub.$emit('quote-reply', {
          discussionId,
          text,
          event: e,
        });
      } else {
        // Selection is from description, append it to top-level comment form,
        this.appendText(text);
      }
    },
    appendText(text) {
      // Based on selected sort order of discussion timeline,
      // we have to choose correct <work-item-add-note/> reference.
      // We're using `append` method from ~/vue_shared/components/markdown/markdown_editor.vue
      this.$refs[this.formAtTop ? 'addNoteTop' : 'addNoteBottom'].appendText(text);
    },
    getDiscussionKey(discussion) {
      // discussion key is important like this since after first comment changes
      const discussionId = discussion.id;
      return discussionId.split('/')[discussionId.split('/').length - 1];
    },
    isSystemNote(note) {
      return note.notes.nodes[0].system;
    },
    setSort(direction) {
      this.sortOrder = direction;
    },
    setFilter(filterValue) {
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
      return !discussion.resolved || this.isHashTargeted(discussion);
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
      this.noteToDelete = { ...note, isLastNote, discussionId: discussion.id };
    },
    cancelDeletingNote() {
      this.noteToDelete = null;
    },
    updateDiscussionsCount(value) {
      if (typeof value !== 'number') return;

      const { cache } = this.$apollo.provider.defaultClient;

      cache.modify({
        id: cache.identify({ __typename: 'WorkItem', id: this.workItemId }),
        fields: {
          userDiscussionsCount(existingCount = 0) {
            return Math.max(0, existingCount + value);
          },
        },
      });
    },
    async deleteNote() {
      try {
        const { id, isLastNote, discussionId } = this.noteToDelete;
        const { updateDiscussionsCount } = this;
        await this.$apollo.mutate({
          mutation: deleteNoteMutation,
          variables: {
            input: {
              id,
            },
          },
          update(cache) {
            const deletedObject = isLastNote
              ? { __typename: TYPENAME_DISCUSSION, id: discussionId }
              : { __typename: TYPENAME_NOTE, id };
            cache.modify({
              id: cache.identify(deletedObject),
              fields: (_, { DELETE }) => DELETE,
            });
            if (!discussionId || isLastNote) updateDiscussionsCount(-1);
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
      :can-summarize-comments="canSummarizeComments"
      :sort-order="sortOrder"
      :disable-activity-filter-sort="disableActivityFilterSort"
      :work-item-id="workItemId"
      :work-item-type="workItemType"
      :discussion-filter="discussionFilter"
      :use-h2="useH2"
      :small-header-style="smallHeaderStyle"
      @changeSort="setSort"
      @changeFilter="setFilter"
    />
    <div class="issuable-discussion gl-mb-5 !gl-clearfix">
      <div v-if="formAtTop && !commentsDisabled && markdownPathsLoaded" class="js-comment-form">
        <ul class="notes notes-form timeline">
          <work-item-add-note
            ref="addNoteTop"
            v-bind="workItemCommentFormProps"
            :hide-fullscreen-markdown-button="hideFullscreenMarkdownButton"
            :is-group-work-item="isGroup"
            :uploads-path="uploadsPath"
            :discussions-sort-order="initialSortOrder"
            @startEditing="$emit('startEditing')"
            @stopEditing="$emit('stopEditing')"
            @error="$emit('error', $event)"
            @updateCount="updateDiscussionsCount"
          />
        </ul>
      </div>
      <ul class="notes main-notes-list timeline">
        <template v-for="discussion in notesArray">
          <system-note
            v-if="isSystemNote(discussion)"
            :key="discussion.notes.nodes[0].id"
            :note="discussion.notes.nodes[0]"
          />
          <work-item-discussion
            v-else-if="markdownPathsLoaded"
            :key="getDiscussionKey(discussion)"
            ref="workItemDiscussion"
            :discussion="discussion"
            :full-path="fullPath"
            :work-item-id="workItemId"
            :work-item-iid="workItemIid"
            :work-item-type="workItemType"
            :is-modal="isModal"
            :autocomplete-data-sources="autocompleteDataSources"
            :markdown-preview-path="markdownPreviewPath"
            :new-comment-template-paths="newCommentTemplatePaths"
            :assignees="assignees"
            :can-reply="canCreateNote"
            :can-set-work-item-metadata="canSetWorkItemMetadata"
            :is-discussion-locked="isDiscussionLocked"
            :is-work-item-confidential="isWorkItemConfidential"
            :is-expanded-on-load="isDiscussionExpandedOnLoad(discussion)"
            :hide-fullscreen-markdown-button="hideFullscreenMarkdownButton"
            :uploads-path="uploadsPath"
            @deleteNote="showDeleteNoteModal($event, discussion)"
            @reportAbuse="reportAbuse(true, $event)"
            @error="$emit('error', $event)"
            @startEditing="$emit('startEditing')"
            @cancelEditing="$emit('stopEditing')"
          />
        </template>

        <work-item-history-only-filter-note v-if="commentsDisabled" @changeFilter="setFilter" />
      </ul>
      <work-item-notes-loading v-if="initialLoading || (isLoadingMore && !notesCached)" />
      <div v-if="!formAtTop && !commentsDisabled && markdownPathsLoaded" class="js-comment-form">
        <ul class="notes notes-form timeline">
          <work-item-add-note
            ref="addNoteBottom"
            v-bind="workItemCommentFormProps"
            :hide-fullscreen-markdown-button="hideFullscreenMarkdownButton"
            :is-group-work-item="isGroup"
            :uploads-path="uploadsPath"
            @startEditing="$emit('startEditing')"
            @stopEditing="$emit('stopEditing')"
            @error="$emit('error', $event)"
            @focus="$emit('focus')"
            @blur="$emit('blur')"
            @updateCount="updateDiscussionsCount"
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
Use cache.modify instead of writeQuery to update userDiscussionsCount
