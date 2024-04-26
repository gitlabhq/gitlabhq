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
  <div class="edit-timeline-event gl-relative gl-display-flex gl-align-items-center">
    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-align-self-start gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-2 gl-w-8 gl-h-8 gl-z-1"
    >
      <gl-icon name="comment" class="note-icon" />
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
