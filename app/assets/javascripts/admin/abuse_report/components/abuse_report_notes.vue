<script>
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import SkeletonLoadingContainer from '~/vue_shared/components/notes/skeleton_note.vue';
import { SKELETON_NOTES_COUNT } from '~/admin/abuse_report/constants';
import abuseReportNotesQuery from '../graphql/notes/abuse_report_notes.query.graphql';
import AbuseReportDiscussion from './notes/abuse_report_discussion.vue';
import AbuseReportAddNote from './notes/abuse_report_add_note.vue';

export default {
  name: 'AbuseReportNotes',
  SKELETON_NOTES_COUNT,
  i18n: {
    fetchError: __('An error occurred while fetching comments, please try again.'),
  },
  components: {
    SkeletonLoadingContainer,
    AbuseReportDiscussion,
    AbuseReportAddNote,
  },
  props: {
    abuseReportId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      addNoteKey: uniqueId(`abuse-report-add-note-${this.abuseReportId}`),
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    abuseReportNotes: {
      query: abuseReportNotesQuery,
      variables() {
        return {
          id: this.abuseReportId,
        };
      },
      update(data) {
        return data.abuseReport?.discussions || [];
      },
      skip() {
        return !this.abuseReportId;
      },
      error() {
        createAlert({ message: this.$options.i18n.fetchError });
      },
    },
  },
  computed: {
    initialLoading() {
      return this.$apollo.queries.abuseReportNotes.loading;
    },
    notesArray() {
      return this.abuseReportNotes?.nodes || [];
    },
  },
  methods: {
    getDiscussionKey(discussion) {
      const discussionId = discussion.notes.nodes[0].id;
      return discussionId.split('/')[discussionId.split('/').length - 1];
    },
    updateKey() {
      this.addNoteKey = uniqueId(`abuse-report-add-note-${this.abuseReportId}`);
    },
  },
};
</script>

<template>
  <div>
    <div class="issuable-discussion gl-mb-5 !gl-clearfix">
      <template v-if="initialLoading">
        <ul class="notes main-notes-list timeline">
          <skeleton-loading-container
            v-for="index in $options.SKELETON_NOTES_COUNT"
            :key="index"
            class="note-skeleton"
          />
        </ul>
      </template>

      <template v-else>
        <ul class="notes main-notes-list timeline">
          <abuse-report-discussion
            v-for="discussion in notesArray"
            :key="getDiscussionKey(discussion)"
            :discussion="discussion.notes.nodes"
            :abuse-report-id="abuseReportId"
          />
        </ul>
        <div class="js-comment-form">
          <ul class="notes notes-form timeline">
            <abuse-report-add-note
              :key="addNoteKey"
              :is-new-discussion="true"
              :abuse-report-id="abuseReportId"
              @cancelEditing="updateKey"
            />
          </ul>
        </div>
      </template>
    </div>
  </div>
</template>
