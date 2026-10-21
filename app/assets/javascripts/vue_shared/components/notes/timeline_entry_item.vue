<script>
export default {
  name: 'TimelineEntryItem',
  emits: ['mouseenter', 'mouseleave'],
};
</script>

<template>
  <li
    class="js-timeline-entry timeline-entry note-container-query-wrapper"
    @mouseenter="$emit('mouseenter', $event)"
    @mouseleave="$emit('mouseleave', $event)"
  >
    <div class="timeline-entry-inner gl-clearfix"><slot></slot></div>
  </li>
</template>
