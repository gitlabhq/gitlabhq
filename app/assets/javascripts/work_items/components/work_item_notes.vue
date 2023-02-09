<script>
import { GlSkeletonLoader, GlModal } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__, __ } from '~/locale';
import { TYPENAME_DISCUSSION, TYPENAME_NOTE } from '~/graphql_shared/constants';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import { i18n, DEFAULT_PAGE_SIZE_NOTES } from '~/work_items/constants';
import { ASC, DESC } from '~/notes/constants';
import { getWorkItemNotesQuery } from '~/work_items/utils';
import WorkItemDiscussion from '~/work_items/components/notes/work_item_discussion.vue';
import deleteNoteMutation from '../graphql/notes/delete_work_item_notes.mutation.graphql';
import WorkItemCommentForm from './work_item_comment_form.vue';

export default {
  i18n: {
    ACTIVITY_LABEL: s__('WorkItem|Activity'),
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  components: {
    GlSkeletonLoader,
    GlModal,
    ActivityFilter,
    SystemNote,
    WorkItemCommentForm,
    WorkItemDiscussion,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoadingMore: false,
      perPage: DEFAULT_PAGE_SIZE_NOTES,
      sortOrder: ASC,
      noteToDelete: null,
    };
  },
  computed: {
    initialLoading() {
      return this.$apollo.queries.workItemNotes.loading && !this.isLoadingMore;
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
    showLoadingMoreSkeleton() {
      return this.isLoadingMore && !this.changeNotesSortOrderAfterLoading;
    },
    disableActivityFilter() {
      return this.initialLoading || this.isLoadingMore;
    },
    formAtTop() {
      return this.sortOrder === DESC;
    },
    workItemCommentFormProps() {
      return {
        queryVariables: this.queryVariables,
        fullPath: this.fullPath,
        workItemId: this.workItemId,
        fetchByIid: this.fetchByIid,
        workItemType: this.workItemType,
        sortOrder: this.sortOrder,
      };
    },
    notesArray() {
      const notes = this.workItemNotes?.nodes || [];

      if (this.sortOrder === DESC) {
        return [...notes].reverse();
      }
      return notes;
    },
  },
  apollo: {
    workItemNotes: {
      query() {
        return getWorkItemNotesQuery(this.fetchByIid);
      },
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          ...this.queryVariables,
          after: this.after,
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
        };
      },
      update(data) {
        const workItemWidgets = this.fetchByIid
          ? data.workspace?.workItems?.nodes[0]?.widgets
          : data.workItem?.widgets;
        const discussionNodes =
          workItemWidgets.find((widget) => widget.type === 'NOTES')?.discussions || [];
        return discussionNodes;
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
      result() {
        this.updateSortingOrderIfApplicable();

        if (this.hasNextPage) {
          this.fetchMoreNotes();
        }
      },
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
    updateSortingOrderIfApplicable() {
      // when the sort order is DESC in local storage and there is only a single page, call
      // changeSortOrder manually
      if (
        this.changeNotesSortOrderAfterLoading &&
        this.perPage === DEFAULT_PAGE_SIZE_NOTES &&
        !this.hasNextPage
      ) {
        this.changeNotesSortOrder(DESC);
      }
    },
    changeNotesSortOrder(direction) {
      this.sortOrder = direction;
    },
    async fetchMoreNotes() {
      this.isLoadingMore = true;
      // copied from discussions batch logic - every fetchMore call has a higher
      // amount of page size than the previous one with the limit being 100
      this.perPage = Math.min(Math.round(this.perPage * 1.5), 100);
      await this.$apollo.queries.workItemNotes
        .fetchMore({
          variables: {
            ...this.queryVariables,
            pageSize: this.perPage,
            after: this.pageInfo?.endCursor,
          },
        })
        .catch((error) => this.$emit('error', error.message));
      this.isLoadingMore = false;
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
  <div class="gl-border-t gl-mt-5 work-item-notes">
    <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
      <label class="gl-mb-0">{{ $options.i18n.ACTIVITY_LABEL }}</label>
      <activity-filter
        class="gl-min-h-5 gl-pb-3"
        :loading="disableActivityFilter"
        :sort-order="sortOrder"
        :work-item-type="workItemType"
        @changeSortOrder="changeNotesSortOrder"
        @updateSavedSortOrder="changeNotesSortOrder"
      />
    </div>
    <div v-if="initialLoading" class="gl-mt-5">
      <gl-skeleton-loader
        v-for="index in $options.loader.repeat"
        :key="index"
        :width="$options.loader.width"
        :height="$options.loader.height"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <circle cx="20" cy="20" r="16" />
        <rect width="500" x="45" y="15" height="10" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div v-else class="issuable-discussion gl-mb-5 gl-clearfix!">
      <template v-if="!initialLoading">
        <ul class="notes main-notes-list timeline gl-clearfix!">
          <work-item-comment-form
            v-if="formAtTop"
            v-bind="workItemCommentFormProps"
            @error="$emit('error', $event)"
          />

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
                :query-variables="queryVariables"
                :full-path="fullPath"
                :work-item-id="workItemId"
                :fetch-by-iid="fetchByIid"
                :work-item-type="workItemType"
                @deleteNote="showDeleteNoteModal($event, discussion)"
              />
            </template>
          </template>

          <work-item-comment-form
            v-if="!formAtTop"
            v-bind="workItemCommentFormProps"
            @error="$emit('error', $event)"
          />
        </ul>
      </template>

      <template v-if="showLoadingMoreSkeleton">
        <gl-skeleton-loader
          v-for="index in $options.loader.repeat"
          :key="index"
          :width="$options.loader.width"
          :height="$options.loader.height"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <circle cx="20" cy="20" r="16" />
          <rect width="500" x="45" y="15" height="10" rx="4" />
        </gl-skeleton-loader>
      </template>
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
