<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ASC } from '~/notes/constants';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import toggleWorkItemNoteResolveDiscussion from '~/work_items/graphql/notes/toggle_work_item_note_resolve_discussion.mutation.graphql';
import DiscussionNotesRepliesWrapper from '~/notes/components/discussion_notes_replies_wrapper.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import WorkItemNoteReplying from '~/work_items/components/notes/work_item_note_replying.vue';
import WorkItemAddNote from './work_item_add_note.vue';

export default {
  components: {
    TimelineEntryItem,
    WorkItemNote,
    WorkItemAddNote,
    ToggleRepliesWidget,
    DiscussionNotesRepliesWrapper,
    WorkItemNoteReplying,
  },
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
    discussion: {
      type: Array,
      required: true,
    },
    sortOrder: {
      type: String,
      default: ASC,
      required: false,
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
    isExpandedOnLoad: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpanded: this.isExpandedOnLoad,
      autofocus: false,
      isReplying: false,
      replyingText: '',
      showForm: false,
      isResolving: false,
    };
  },
  computed: {
    note() {
      return this.discussion[0];
    },
    noteId() {
      return getIdFromGraphQLId(this.note.id);
    },
    hasReplies() {
      return Boolean(this.replies?.length);
    },
    replies() {
      if (this.discussion?.length > 1) {
        return this.discussion.slice(1);
      }
      return null;
    },
    discussionId() {
      return this.firstComment?.id || '';
    },
    shouldShowReplyForm() {
      return this.showForm || this.hasReplies;
    },
    isOnlyCommentOfAThread() {
      return !this.hasReplies && !this.showForm;
    },
    firstComment() {
      return this.discussion[0]?.discussion;
    },
    isDiscussionResolved() {
      return this.firstComment?.resolved;
    },
    isDiscussionResolvable() {
      return this.firstComment?.resolvable && this.note?.userPermissions?.resolveNote;
    },
  },
  watch: {
    discussion: {
      handler(newDiscussion) {
        if (newDiscussion[0].discussion.resolved === false) {
          this.isExpanded = true;
        }
      },
      deep: true,
    },
  },
  methods: {
    showReplyForm() {
      this.showForm = true;
      this.isExpanded = true;
      this.autofocus = true;
    },
    hideReplyForm() {
      this.showForm = false;
      this.isExpanded = this.hasReplies;
      this.autofocus = false;
      this.$emit('cancelEditing');
    },
    toggleDiscussion() {
      this.isExpanded = !this.isExpanded;
    },
    threadKey(note) {
      return `${note.id}-thread`; // eslint-disable-line @gitlab/require-i18n-strings
    },
    onReplied() {
      this.isExpanded = true;
      this.isReplying = false;
      this.replyingText = '';
    },
    onReplying(commentText) {
      this.isReplying = true;
      this.replyingText = commentText;
    },
    getToggledDiscussion(resolved) {
      let resolvedBy = null;
      if (resolved) {
        resolvedBy = {
          id: gon?.current_user_id,
          name: gon?.current_user_fullname,
          __typename: 'UserCore',
        };
      }
      const toggledDiscussionNotes = [...this.discussion].map((note) => {
        return {
          ...note,
          discussion: {
            ...note.discussion,
            resolved,
            resolvedBy,
          },
        };
      });
      return {
        id: this.discussionId,
        notes: {
          nodes: [...toggledDiscussionNotes],
        },
      };
    },
    async resolveDiscussion() {
      this.isResolving = true;
      try {
        await this.$apollo.mutate({
          mutation: toggleWorkItemNoteResolveDiscussion,
          variables: { id: this.discussionId, resolve: !this.isDiscussionResolved },
          optimisticResponse: {
            discussionToggleResolve: {
              errors: [],
              discussion: this.getToggledDiscussion(!this.isDiscussionResolved),
              __typename: 'DiscussionToggleResolvePayload',
            },
          },
        });
      } catch (error) {
        this.$emit('error', error.message);
      } finally {
        this.isResolving = false;
      }
    },
  },
};
</script>

<template>
  <work-item-note
    v-if="isOnlyCommentOfAThread"
    :is-first-note="true"
    :note="note"
    :discussion-id="discussionId"
    :full-path="fullPath"
    :has-replies="hasReplies"
    :work-item-type="workItemType"
    :is-modal="isModal"
    :autocomplete-data-sources="autocompleteDataSources"
    :markdown-preview-path="markdownPreviewPath"
    :new-comment-template-paths="newCommentTemplatePaths"
    :class="{ 'gl-mb-4': hasReplies }"
    :assignees="assignees"
    :can-set-work-item-metadata="canSetWorkItemMetadata"
    :is-discussion-resolved="isDiscussionResolved"
    :is-discussion-resolvable="isDiscussionResolvable"
    :work-item-id="workItemId"
    :work-item-iid="workItemIid"
    :is-resolving="isResolving"
    @startEditing="$emit('startEditing')"
    @resolve="resolveDiscussion"
    @startReplying="showReplyForm"
    @deleteNote="$emit('deleteNote', note)"
    @reportAbuse="$emit('reportAbuse', note)"
    @cancelEditing="$emit('cancelEditing')"
    @error="$emit('error', $event)"
  />
  <timeline-entry-item v-else :data-note-id="noteId" class="note note-discussion gl-px-0">
    <div class="timeline-content">
      <div class="discussion">
        <div class="discussion-body">
          <div class="discussion-wrapper">
            <div class="discussion-notes">
              <ul class="notes">
                <work-item-note
                  is-first-note
                  :note="note"
                  :discussion-id="discussionId"
                  :full-path="fullPath"
                  :has-replies="hasReplies"
                  :work-item-type="workItemType"
                  :is-modal="isModal"
                  :class="{ 'gl-mb-4': hasReplies }"
                  :autocomplete-data-sources="autocompleteDataSources"
                  :markdown-preview-path="markdownPreviewPath"
                  :new-comment-template-paths="newCommentTemplatePaths"
                  :assignees="assignees"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :can-set-work-item-metadata="canSetWorkItemMetadata"
                  :is-discussion-resolved="isDiscussionResolved"
                  :is-discussion-resolvable="isDiscussionResolvable"
                  :is-resolving="isResolving"
                  @startReplying="showReplyForm"
                  @startEditing="$emit('startEditing')"
                  @deleteNote="$emit('deleteNote', note)"
                  @reportAbuse="$emit('reportAbuse', note)"
                  @cancelEditing="$emit('cancelEditing')"
                  @resolve="resolveDiscussion"
                  @error="$emit('error', $event)"
                />
                <discussion-notes-replies-wrapper>
                  <toggle-replies-widget
                    v-if="hasReplies"
                    :collapsed="!isExpanded"
                    :replies="replies"
                    @toggle="toggleDiscussion({ discussionId })"
                  />
                  <template v-if="isExpanded">
                    <template v-for="reply in replies">
                      <work-item-note
                        :key="threadKey(reply)"
                        :discussion-id="discussionId"
                        :full-path="fullPath"
                        :note="reply"
                        :work-item-type="workItemType"
                        :is-modal="isModal"
                        :autocomplete-data-sources="autocompleteDataSources"
                        :markdown-preview-path="markdownPreviewPath"
                        :new-comment-template-paths="newCommentTemplatePaths"
                        :assignees="assignees"
                        :work-item-id="workItemId"
                        :work-item-iid="workItemIid"
                        :can-set-work-item-metadata="canSetWorkItemMetadata"
                        :is-discussion-resolved="isDiscussionResolved"
                        :is-discussion-resolvable="isDiscussionResolvable"
                        :is-resolving="isResolving"
                        @startReplying="showReplyForm"
                        @deleteNote="$emit('deleteNote', reply)"
                        @reportAbuse="$emit('reportAbuse', reply)"
                        @startEditing="$emit('startEditing')"
                        @cancelEditing="$emit('cancelEditing')"
                        @error="$emit('error', $event)"
                      />
                    </template>
                    <work-item-note-replying
                      v-if="isReplying"
                      :is-internal-note="note.internal"
                      :body="replyingText"
                    />
                    <work-item-add-note
                      v-if="shouldShowReplyForm"
                      :notes-form="false"
                      :autofocus="autofocus"
                      :full-path="fullPath"
                      :work-item-id="workItemId"
                      :work-item-iid="workItemIid"
                      :discussion-id="discussionId"
                      :work-item-type="workItemType"
                      :sort-order="sortOrder"
                      :add-padding="true"
                      :autocomplete-data-sources="autocompleteDataSources"
                      :markdown-preview-path="markdownPreviewPath"
                      :new-comment-template-paths="newCommentTemplatePaths"
                      :is-discussion-locked="isDiscussionLocked"
                      :is-internal-thread="note.internal"
                      :is-work-item-confidential="isWorkItemConfidential"
                      :is-discussion-resolved="isDiscussionResolved"
                      :is-discussion-resolvable="isDiscussionResolvable"
                      :is-resolving="isResolving"
                      :has-replies="hasReplies"
                      @startReplying="showReplyForm"
                      @cancelEditing="hideReplyForm"
                      @replied="onReplied"
                      @replying="onReplying"
                      @resolve="resolveDiscussion"
                      @error="$emit('error', $event)"
                      @startEditing="$emit('startEditing')"
                    />
                  </template>
                </discussion-notes-replies-wrapper>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
