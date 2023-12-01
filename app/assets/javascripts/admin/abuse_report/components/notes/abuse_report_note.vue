<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteBody from './abuse_report_note_body.vue';
import AbuseReportNoteActions from './abuse_report_note_actions.vue';

export default {
  name: 'AbuseReportNote',
  directives: {
    SafeHtml,
  },
  components: {
    GlAvatarLink,
    GlAvatar,
    TimelineEntryItem,
    NoteHeader,
    NoteBody,
    AbuseReportNoteActions,
  },
  props: {
    abuseReportId: {
      type: String,
      required: true,
    },
    note: {
      type: Object,
      required: true,
    },
    showReplyButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    noteAnchorId() {
      return `note_${getIdFromGraphQLId(this.note.id)}`;
    },
    author() {
      return this.note.author;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
  },
  methods: {
    startReplying() {
      this.$emit('startReplying');
    },
  },
};
</script>

<template>
  <timeline-entry-item :id="noteAnchorId" class="note note-wrapper note-comment">
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
        <div class="note-header">
          <note-header
            :author="author"
            :created-at="note.createdAt"
            :note-id="note.id"
            :note-url="note.url"
          >
            <span v-if="note.createdAt" class="d-none d-sm-inline">&middot;</span>
          </note-header>
          <div class="gl-display-inline-flex">
            <abuse-report-note-actions
              :show-reply-button="showReplyButton"
              @startReplying="startReplying"
            />
          </div>
        </div>

        <div class="timeline-discussion-body">
          <note-body ref="noteBody" :note="note" />
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
