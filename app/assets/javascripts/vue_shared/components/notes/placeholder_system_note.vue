<script>
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

/**
 * Common component to render a placeholder system note.
 *
 * @example
 * <placeholder-system-note
 *  :note="{ body: 'Commands are being applied'}"
 *  />
 */
export default {
  name: 'PlaceholderSystemNote',
  components: {
    TimelineEntryItem,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <timeline-entry-item class="note system-note being-posted fade-in-half">
    <div class="timeline-content">
      <em>{{ note.body }}</em>
    </div>
  </timeline-entry-item>
</template>
