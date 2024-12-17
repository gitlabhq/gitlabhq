<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import { createAlert } from '~/alert';
import { sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import IncidentTimelineEventItem from './timeline_events_item.vue';
import EditTimelineEvent from './edit_timeline_event.vue';
import deleteTimelineEvent from './graphql/queries/delete_timeline_event.mutation.graphql';
import editTimelineEvent from './graphql/queries/edit_timeline_event.mutation.graphql';
import { timelineListI18n } from './constants';

export default {
  name: 'IncidentTimelineEventList',
  i18n: timelineListI18n,
  components: {
    IncidentTimelineEventItem,
    EditTimelineEvent,
  },
  props: {
    timelineEventLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
    timelineEvents: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  data() {
    return { eventToEdit: null, editTimelineEventActive: false };
  },
  computed: {
    dateGroupedEvents() {
      const groupedEvents = new Map();

      this.timelineEvents.forEach((event) => {
        const date = formatDate(event.occurredAt, 'isoDate', true);

        if (groupedEvents.has(date)) {
          groupedEvents.get(date).push(event);
        } else {
          groupedEvents.set(date, [event]);
        }
      });

      return groupedEvents;
    },
  },
  methods: {
    handleEditSelection(event) {
      this.eventToEdit = event.id;
      this.$emit('hide-new-incident-timeline-event-form');
    },
    hideEdit() {
      this.eventToEdit = null;
    },
    handleDelete: ignoreWhilePending(async function handleDelete(event) {
      const msg = this.$options.i18n.deleteModal;

      const confirmed = await confirmAction(msg, {
        primaryBtnVariant: 'danger',
        primaryBtnText: this.$options.i18n.deleteButton,
      });

      if (!confirmed) {
        return;
      }

      try {
        const result = await this.$apollo.mutate({
          mutation: deleteTimelineEvent,
          variables: {
            input: {
              id: event.id,
            },
          },
          update: (cache) => {
            const cacheId = cache.identify(event);
            cache.evict({ id: cacheId });
          },
        });
        const { errors } = result.data.timelineEventDestroy;
        if (errors?.length) {
          createAlert({
            message: sprintf(this.$options.i18n.deleteError, { error: errors.join('. ') }, false),
          });
        }
      } catch (error) {
        createAlert({ message: this.$options.i18n.deleteErrorGeneric, captureError: true, error });
      }
    }),
    handleSaveEdit(eventDetails) {
      this.editTimelineEventActive = true;
      return this.$apollo
        .mutate({
          mutation: editTimelineEvent,
          variables: {
            input: {
              id: eventDetails.id,
              note: eventDetails.note,
              occurredAt: eventDetails.occurredAt,
              timelineEventTagNames: eventDetails.timelineEventTags,
            },
          },
        })
        .then(({ data }) => {
          this.editTimelineEventActive = false;
          const errors = data.timelineEventUpdate?.errors;
          if (errors.length) {
            createAlert({
              message: sprintf(this.$options.i18n.editError, { error: errors.join('. ') }, false),
            });
          } else {
            this.hideEdit();
          }
        })
        .catch((error) => {
          createAlert({
            message: this.$options.i18n.editErrorGeneric,
            captureError: true,
            error,
          });
        });
    },
  },
};
</script>

<template>
  <div class="issuable-discussion incident-timeline-events -gl-mt-3">
    <div
      v-for="[eventDate, events] in dateGroupedEvents"
      :key="eventDate"
      data-testid="timeline-group"
      class="timeline-group"
    >
      <h2
        class="gl-my-0 gl-border-1 gl-border-subtle gl-py-5 gl-text-size-h2 gl-border-b-solid"
        data-testid="event-date"
      >
        {{ eventDate }}
      </h2>

      <ul class="notes main-notes-list gl-mt-4">
        <li
          v-for="(event, eventIndex) in events"
          :key="eventIndex"
          class="timeline-entry-vertical-line timeline-entry note system-note note-wrapper !gl-my-0 !gl-pr-0"
        >
          <edit-timeline-event
            v-if="eventToEdit === event.id"
            :key="`edit-${event.id}`"
            ref="eventForm"
            :event="event"
            :edit-timeline-event-active="editTimelineEventActive"
            @handle-save-edit="handleSaveEdit"
            @hide-edit="hideEdit()"
            @delete="handleDelete(event)"
          />
          <incident-timeline-event-item
            v-else
            :key="event.id"
            :action="event.action"
            :occurred-at="event.occurredAt"
            :note-html="event.noteHtml"
            :event-tags="event.timelineEventTags.nodes"
            @delete="handleDelete(event)"
            @edit="handleEditSelection(event)"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
