<script>
  /**
   * Common component to render a system note, icon and user information.
   *
   * This component needs to be used with a vuex store.
   * That vuex store needs to have a `targetNoteHash` getter
   *
   * @example
   * <system-note
   *   :note="{
   *     id: String,
   *     author: Object,
   *     createdAt: String,
   *     note_html: String,
   *     system_note_icon_name: String
   *    }"
   *   />
   */
  import { mapGetters } from 'vuex';
  import noteHeader from '~/notes/components/note_header.vue';
  import { spriteIcon } from '../../../lib/utils/common_utils';

  export default {
    name: 'SystemNote',
    components: {
      noteHeader,
    },
    props: {
      note: {
        type: Object,
        required: true,
      },
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
      iconHtml() {
        return spriteIcon(this.note.system_note_icon_name);
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
      <div
        class="timeline-icon"
        v-html="iconHtml">
      </div>
      <div class="timeline-content">
        <div class="note-header">
          <note-header
            :author="note.author"
            :created-at="note.created_at"
            :note-id="note.id"
            :action-text-html="note.note_html"
          />
        </div>
      </div>
    </div>
  </li>
</template>
