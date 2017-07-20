<script>
import { mapGetters } from 'vuex';
import iconsMap from './issue_note_icons';
import issueNoteHeader from './issue_note_header.vue';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      svg: iconsMap[this.note.system_note_icon_name],
    };
  },
  components: {
    issueNoteHeader,
  },
  computed: {
    ...mapGetters([
      'targetNoteHash',
    ]),
    noteAnchorId() {
      return `note_${this.note.id}`;
    },
    isTargetNote() {
      return this.targetNoteHash === this.noteAnchorId;
    },
  },
};
</script>

<template>
  <li
    :id="noteAnchorId"
    :class="{ target: isTargetNote }"
    class="note system-note timeline-entry">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
        <span v-html="svg"></span>
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <issue-note-header
            :author="note.author"
            :created-at="note.created_at"
            :note-id="note.id"
            :action-text-html="note.note_html" />
        </div>
      </div>
    </div>
  </li>
</template>
