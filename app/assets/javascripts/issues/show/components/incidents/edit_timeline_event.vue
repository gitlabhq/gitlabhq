<script>
import { GlIcon } from '@gitlab/ui';
import TimelineEventsForm from './timeline_events_form.vue';

export default {
  name: 'EditTimelineEvent',
  components: {
    TimelineEventsForm,
    GlIcon,
  },
  props: {
    event: {
      type: Object,
      required: true,
      validator: (item) => ['occurredAt', 'note'].every((key) => item[key]),
    },
    editTimelineEventActive: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    saveEvent(eventDetails) {
      this.$emit('handle-save-edit', { ...eventDetails, id: this.event.id }, false);
    },
  },
};
</script>

<template>
  <div class="edit-timeline-event gl-relative gl-flex gl-items-center">
    <div
      class="gl-z-1 gl-mt-2 gl-flex gl-h-8 gl-w-8 gl-items-center gl-justify-center gl-self-start gl-rounded-full gl-border-1 gl-border-solid gl-border-default gl-bg-default"
    >
      <gl-icon name="comment" class="note-icon" variant="subtle" />
    </div>
    <timeline-events-form
      ref="eventForm"
      class="timeline-event-border"
      :is-event-processed="editTimelineEventActive"
      :previous-occurred-at="event.occurredAt"
      :previous-note="event.note"
      :previous-tags="event.timelineEventTags.nodes"
      is-editing
      @save-event="saveEvent"
      @cancel="$emit('hide-edit')"
      @delete="$emit('delete')"
    />
  </div>
</template>
