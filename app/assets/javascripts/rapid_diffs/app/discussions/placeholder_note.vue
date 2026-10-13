<script>
import { mapState } from 'pinia';
import { renderMarkdown } from '~/notes/utils';
import { useNotes } from '~/notes/store/legacy_notes';
import { gfm } from '~/vue_shared/directives/gfm';
import NoteHeader from './note_header.vue';
import TimelineEntryItem from './timeline_entry_item.vue';

export default {
  name: 'PlaceholderNote',
  components: {
    NoteHeader,
    TimelineEntryItem,
  },
  directives: {
    gfm,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(useNotes, ['getUserData']),
    renderedNote() {
      return renderMarkdown(this.note.body);
    },
  },
};
</script>

<template>
  <timeline-entry-item class="fade-in-half" data-testid="placeholder-note">
    <template #content>
      <div>
        <div class="gl-flex gl-flex-wrap gl-items-start gl-gap-2 gl-px-4 gl-pt-2">
          <note-header class="gl-my-1 gl-py-2" :author="getUserData" />
        </div>
        <div class="gl-ml-2 gl-pb-4 gl-pl-8 gl-pr-4">
          <div v-gfm="renderedNote" class="note-text md"></div>
        </div>
      </div>
    </template>
  </timeline-entry-item>
</template>
