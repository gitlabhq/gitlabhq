<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import EditedAt from '~/issues/show/components/edited.vue';
import AbuseReportEditNote from './abuse_report_edit_note.vue';
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
    AbuseReportEditNote,
    NoteHeader,
    NoteBody,
    AbuseReportNoteActions,
    EditedAt,
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
  data() {
    return {
      isEditing: false,
      updatedNote: this.note,
    };
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
    showEditButton() {
      return true;
    },
    editedAtClasses() {
      return this.showReplyButton ? 'gl-text-subtle gl-pl-3' : 'gl-text-subtle gl-pl-8';
    },
  },
  methods: {
    startEditing() {
      this.isEditing = true;
    },
    cancelEditing() {
      this.isEditing = false;
    },
    updateNote(note) {
      this.updatedNote = note;
      this.isEditing = false;
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
    <div class="timeline-content !gl-pb-4">
      <abuse-report-edit-note
        v-if="isEditing"
        :abuse-report-id="abuseReportId"
        :note="updatedNote"
        @cancelEditing="cancelEditing"
        @updateNote="updateNote"
      />
      <div v-else data-testid="note-wrapper">
        <div class="note-header">
          <note-header
            :author="author"
            :created-at="note.createdAt"
            :note-id="note.id"
            :note-url="note.url"
          >
            <span v-if="note.createdAt" class="gl-hidden sm:gl-inline">&middot;</span>
          </note-header>
          <div class="gl-inline-flex">
            <abuse-report-note-actions
              :show-reply-button="showReplyButton"
              :show-edit-button="showEditButton"
              @startReplying="$emit('startReplying')"
              @startEditing="startEditing"
            />
          </div>
        </div>

        <div class="timeline-discussion-body">
          <note-body ref="noteBody" :note="updatedNote" />
        </div>

        <edited-at
          v-if="note.lastEditedBy"
          :updated-at="note.lastEditedAt"
          :updated-by-name="note.lastEditedBy.name"
          :updated-by-path="note.lastEditedBy.webPath"
          :class="editedAtClasses"
        />
      </div>
    </div>
  </timeline-entry-item>
</template>
