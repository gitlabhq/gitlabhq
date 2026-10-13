<script>
import TimelineEntryItem from './timeline_entry_item.vue';

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
  <timeline-entry-item class="fade-in-half">
    <template #content>
      <div class="gl-px-4 gl-py-2 gl-text-subtle">
        <em>{{ note.body }}</em>
      </div>
    </template>
  </timeline-entry-item>
</template>
