<script>
import { getLocationHash } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ASC } from '~/notes/constants';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
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
      isExpanded: true,
      autofocus: false,
      isReplying: false,
      replyingText: '',
      showForm: false,
    };
  },
  computed: {
    note() {
      return this.discussion[0];
    },
    author() {
      return this.note.author;
    },
    noteId() {
      return getIdFromGraphQLId(this.note.id);
    },
    noteAnchorId() {
      return `note_${this.noteId}`;
    },
    isTarget() {
      return this.targetNoteHash === this.noteAnchorId;
    },
    targetNoteHash() {
      return getLocationHash();
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
      return this.discussion[0]?.discussion?.id || '';
    },
    shouldShowReplyForm() {
      return this.showForm || this.hasReplies;
    },
    isOnlyCommentOfAThread() {
      return !this.hasReplies && !this.showForm;
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
  },
};
</script>

<template>
  <work-item-note
    v-if="isOnlyCommentOfAThread"
    :is-first-note="true"
    :note="note"
    :discussion-id="discussionId"
    :has-replies="hasReplies"
    :work-item-type="workItemType"
    :is-modal="isModal"
    :autocomplete-data-sources="autocompleteDataSources"
    :markdown-preview-path="markdownPreviewPath"
    :class="{ 'gl-mb-4': hasReplies }"
    :assignees="assignees"
    :can-set-work-item-metadata="canSetWorkItemMetadata"
    :work-item-id="workItemId"
    :query-variables="queryVariables"
    :full-path="fullPath"
    :fetch-by-iid="fetchByIid"
    @startReplying="showReplyForm"
    @deleteNote="$emit('deleteNote', note)"
    @reportAbuse="$emit('reportAbuse', note)"
    @error="$emit('error', $event)"
  />
  <timeline-entry-item
    v-else
    :class="{ 'internal-note': note.internal }"
    :data-note-id="noteId"
    class="note note-discussion gl-px-0"
  >
    <div class="timeline-content">
      <div class="discussion">
        <div class="discussion-body">
          <div class="discussion-wrapper">
            <div class="discussion-notes">
              <ul class="notes">
                <work-item-note
                  :is-first-note="true"
                  :note="note"
                  :discussion-id="discussionId"
                  :has-replies="hasReplies"
                  :work-item-type="workItemType"
                  :is-modal="isModal"
                  :class="{ 'gl-mb-4': hasReplies }"
                  :autocomplete-data-sources="autocompleteDataSources"
                  :markdown-preview-path="markdownPreviewPath"
                  :assignees="assignees"
                  :work-item-id="workItemId"
                  :can-set-work-item-metadata="canSetWorkItemMetadata"
                  :query-variables="queryVariables"
                  :full-path="fullPath"
                  :fetch-by-iid="fetchByIid"
                  @startReplying="showReplyForm"
                  @deleteNote="$emit('deleteNote', note)"
                  @reportAbuse="$emit('reportAbuse', note)"
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
                        :note="reply"
                        :work-item-type="workItemType"
                        :is-modal="isModal"
                        :autocomplete-data-sources="autocompleteDataSources"
                        :markdown-preview-path="markdownPreviewPath"
                        :assignees="assignees"
                        :work-item-id="workItemId"
                        :can-set-work-item-metadata="canSetWorkItemMetadata"
                        :query-variables="queryVariables"
                        :full-path="fullPath"
                        :fetch-by-iid="fetchByIid"
                        @startReplying="showReplyForm"
                        @deleteNote="$emit('deleteNote', reply)"
                        @reportAbuse="$emit('reportAbuse', reply)"
                        @error="$emit('error', $event)"
                      />
                    </template>
                    <work-item-note-replying v-if="isReplying" :body="replyingText" />
                    <work-item-add-note
                      v-if="shouldShowReplyForm"
                      :notes-form="false"
                      :autofocus="autofocus"
                      :query-variables="queryVariables"
                      :full-path="fullPath"
                      :work-item-id="workItemId"
                      :fetch-by-iid="fetchByIid"
                      :discussion-id="discussionId"
                      :work-item-type="workItemType"
                      :sort-order="sortOrder"
                      :add-padding="true"
                      :autocomplete-data-sources="autocompleteDataSources"
                      :markdown-preview-path="markdownPreviewPath"
                      @startReplying="showReplyForm"
                      @cancelEditing="hideReplyForm"
                      @replied="onReplied"
                      @replying="onReplying"
                      @error="$emit('error', $event)"
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
