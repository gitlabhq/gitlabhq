<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ignoreWhilePending } from '~/lib/utils/ignore_while_pending';
import IncidentTimelineEventListItem from './timeline_events_list_item.vue';
import deleteTimelineEvent from './graphql/queries/delete_timeline_event.mutation.graphql';
import { timelineListI18n } from './constants';

export default {
  name: 'IncidentTimelineEventList',
  i18n: timelineListI18n,
  components: {
    IncidentTimelineEventListItem,
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
    isLastItem(groups, groupIndex, events, eventIndex) {
      if (groupIndex < groups.size - 1) {
        return false;
      }
      return eventIndex === events.length - 1;
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
  },
};
</script>

<template>
  <div class="issuable-discussion incident-timeline-events">
    <div
      v-for="([eventDate, events], groupIndex) in dateGroupedEvents"
      :key="eventDate"
      data-testid="timeline-group"
    >
      <div class="gl-pb-3 gl-border-gray-50 gl-border-1 gl-border-b-solid">
        <strong class="gl-font-size-h2" data-testid="event-date">{{ eventDate }}</strong>
      </div>
      <ul class="notes main-notes-list gl-pl-n3">
        <incident-timeline-event-list-item
          v-for="(event, eventIndex) in events"
          :key="event.id"
          :action="event.action"
          :occurred-at="event.occurredAt"
          :note-html="event.noteHtml"
          :is-last-item="isLastItem(dateGroupedEvents, groupIndex, events, eventIndex)"
          @delete="handleDelete(event)"
        />
      </ul>
    </div>
  </div>
</template>
