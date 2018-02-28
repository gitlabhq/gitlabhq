<script>
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
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
  };
</script>

<template>
  <li class="note system-note timeline-entry being-posted fade-in-half">
    <div class="timeline-entry-inner">
      <div class="timeline-content">
        <em>{{ note.body }}</em>
      </div>
    </div>
  </li>
</template>
