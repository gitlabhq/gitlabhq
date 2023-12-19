<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import DiscussionNotesRepliesWrapper from '~/notes/components/discussion_notes_replies_wrapper.vue';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import AbuseReportNote from './abuse_report_note.vue';
import AbuseReportAddNote from './abuse_report_add_note.vue';

export default {
  name: 'AbuseReportDiscussion',
  components: {
    TimelineEntryItem,
    DiscussionNotesRepliesWrapper,
    ToggleRepliesWidget,
    AbuseReportNote,
    AbuseReportAddNote,
  },
  props: {
    abuseReportId: {
      type: String,
      required: true,
    },
    discussion: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: true,
      showCommentForm: false,
    };
  },
  computed: {
    note() {
      return this.discussion[0];
    },
    noteId() {
      return getIdFromGraphQLId(this.note.id);
    },
    replies() {
      if (this.discussion?.length > 1) {
        return this.discussion.slice(1);
      }
      return null;
    },
    hasReplies() {
      return Boolean(this.replies?.length);
    },
    discussionId() {
      return this.discussion[0]?.discussion?.id || '';
    },
  },
  methods: {
    toggleDiscussion() {
      this.isExpanded = !this.isExpanded;
    },
    startReplying() {
      this.showCommentForm = true;
    },
    stopReplying() {
      this.showCommentForm = false;
    },
  },
};
</script>

<template>
  <abuse-report-note
    v-if="!hasReplies && !showCommentForm"
    :note="note"
    :abuse-report-id="abuseReportId"
    show-reply-button
    class="gl-mb-4"
    @startReplying="startReplying"
  />
  <timeline-entry-item v-else :data-note-id="noteId" class="note note-discussion gl-px-0">
    <div class="timeline-content">
      <div class="discussion">
        <div class="discussion-body">
          <div class="discussion-wrapper">
            <div class="discussion-notes">
              <ul class="notes">
                <abuse-report-note
                  :note="note"
                  :discussion-id="discussionId"
                  :abuse-report-id="abuseReportId"
                  show-reply-button
                  class="gl-mb-4"
                  @startReplying="startReplying"
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
                      <abuse-report-note
                        :key="reply.id"
                        :discussion-id="discussionId"
                        :note="reply"
                        :abuse-report-id="abuseReportId"
                      />
                    </template>
                    <abuse-report-add-note
                      :discussion-id="discussionId"
                      :is-new-discussion="false"
                      :show-comment-form="showCommentForm"
                      :abuse-report-id="abuseReportId"
                      @cancelEditing="stopReplying"
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
