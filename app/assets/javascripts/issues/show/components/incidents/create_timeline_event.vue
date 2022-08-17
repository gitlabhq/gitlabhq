<script>
import { produce } from 'immer';
import { sortBy } from 'lodash';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { timelineFormI18n } from './constants';
import TimelineEventsForm from './timeline_events_form.vue';

import CreateTimelineEvent from './graphql/queries/create_timeline_event.mutation.graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';

export default {
  name: 'CreateTimelineEvent',
  i18n: timelineFormI18n,
  components: {
    TimelineEventsForm,
  },
  inject: ['fullPath', 'issuableId'],
  props: {
    hasTimelineEvents: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return { createTimelineEventActive: false };
  },
  methods: {
    clearForm() {
      this.$refs.eventForm.clear();
    },
    focusDate() {
      this.$refs.eventForm.focusDate();
    },
    updateCache(store, { data }) {
      const { timelineEvent: event, errors } = data?.timelineEventCreate || {};

      if (errors.length) {
        return;
      }

      const variables = {
        incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
        fullPath: this.fullPath,
      };

      const sourceData = store.readQuery({
        query: getTimelineEvents,
        variables,
      });

      const newData = produce(sourceData, (draftData) => {
        const { nodes: draftEventList } = draftData.project.incidentManagementTimelineEvents;
        draftEventList.push(event);
        // ISOStrings sort correctly in lexical order
        const sortedEvents = sortBy(draftEventList, 'occurredAt');
        draftData.project.incidentManagementTimelineEvents.nodes = sortedEvents;
      });

      store.writeQuery({
        query: getTimelineEvents,
        variables,
        data: newData,
      });
    },
    createIncidentTimelineEvent(eventDetails, addAnotherEvent = false) {
      this.createTimelineEventActive = true;
      return this.$apollo
        .mutate({
          mutation: CreateTimelineEvent,
          variables: {
            input: {
              incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
              note: eventDetails.note,
              occurredAt: eventDetails.occurredAt,
            },
          },
          update: this.updateCache,
        })
        .then(({ data = {} }) => {
          this.createTimelineEventActive = false;
          const errors = data.timelineEventCreate?.errors;
          if (errors.length) {
            createAlert({
              message: sprintf(this.$options.i18n.createError, { error: errors.join('. ') }, false),
            });
            return;
          }
          if (addAnotherEvent) {
            this.$refs.eventForm.clear();
          } else {
            this.$emit('hide-new-timeline-events-form');
          }
        })
        .catch((error) => {
          createAlert({
            message: this.$options.i18n.createErrorGeneric,
            captureError: true,
            error,
          });
        });
    },
  },
};
</script>

<template>
  <timeline-events-form
    ref="eventForm"
    :is-event-processed="createTimelineEventActive"
    :has-timeline-events="hasTimelineEvents"
    @save-event="createIncidentTimelineEvent"
    @cancel="$emit('hide-new-timeline-events-form')"
  />
</template>
