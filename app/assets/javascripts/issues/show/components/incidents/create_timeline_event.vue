<script>
import { produce } from 'immer';
import { sortBy } from 'lodash';
import { GlIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE } from '~/graphql_shared/constants';
import { timelineFormI18n } from './constants';
import TimelineEventsForm from './timeline_events_form.vue';

import CreateTimelineEvent from './graphql/queries/create_timeline_event.mutation.graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';

export default {
  name: 'CreateTimelineEvent',
  i18n: timelineFormI18n,
  components: {
    TimelineEventsForm,
    GlIcon,
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
    updateCache(store, { data }) {
      const { timelineEvent: event, errors } = data?.timelineEventCreate || {};

      if (errors.length) {
        return;
      }

      const variables = {
        incidentId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
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
              incidentId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
              note: eventDetails.note,
              occurredAt: eventDetails.occurredAt,
              timelineEventTagNames: eventDetails.timelineEventTags,
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
  <div class="create-timeline-event gl-relative gl-flex gl-items-start">
    <div
      v-if="hasTimelineEvents"
      class="gl-z-1 gl-mt-2 gl-flex gl-h-8 gl-w-8 gl-shrink-0 gl-items-center gl-justify-center gl-self-start gl-rounded-full gl-border-1 gl-border-solid gl-border-default gl-bg-default gl-p-3"
    >
      <gl-icon name="comment" class="note-icon" variant="subtle" />
    </div>
    <timeline-events-form
      ref="eventForm"
      :class="{ 'gl-border-t gl-border-subtle gl-pt-3': hasTimelineEvents }"
      :is-event-processed="createTimelineEventActive"
      show-save-and-add
      @save-event="createIncidentTimelineEvent"
      @cancel="$emit('hide-new-timeline-events-form')"
    />
  </div>
</template>
