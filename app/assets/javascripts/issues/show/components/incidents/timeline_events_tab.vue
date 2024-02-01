<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE } from '~/graphql_shared/constants';
import { fetchPolicies } from '~/lib/graphql';
import notesEventHub from '~/notes/event_hub';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';
import { displayAndLogError } from './utils';
import { timelineTabI18n } from './constants';
import CreateTimelineEvent from './create_timeline_event.vue';
import IncidentTimelineEventsList from './timeline_events_list.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    CreateTimelineEvent,
    IncidentTimelineEventsList,
  },
  i18n: timelineTabI18n,
  inject: ['canUpdateTimelineEvent', 'fullPath', 'issuableId'],
  data() {
    return {
      isEventFormVisible: false,
      timelineEvents: [],
    };
  },
  apollo: {
    timelineEvents: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getTimelineEvents,
      variables() {
        return {
          fullPath: this.fullPath,
          incidentId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
        };
      },
      update(data) {
        return data.project.incidentManagementTimelineEvents.nodes;
      },
      error(error) {
        displayAndLogError(error);
      },
    },
  },
  computed: {
    timelineEventLoading() {
      return this.$apollo.queries.timelineEvents.loading;
    },
    hasTimelineEvents() {
      return Boolean(this.timelineEvents.length);
    },
    showEmptyState() {
      return !this.timelineEventLoading && !this.hasTimelineEvents;
    },
  },
  mounted() {
    notesEventHub.$on('comment-promoted-to-timeline-event', this.refreshTimelineEvents);
  },
  destroyed() {
    notesEventHub.$off('comment-promoted-to-timeline-event', this.refreshTimelineEvents);
  },
  methods: {
    refreshTimelineEvents() {
      this.$apollo.queries.timelineEvents.refetch();
    },
    hideEventForm() {
      this.isEventFormVisible = false;
    },
    showEventForm() {
      this.isEventFormVisible = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="timelineEventLoading" size="lg" color="dark" class="gl-mt-5" />
    <div v-if="showEmptyState" class="gl-mt-4">
      <p class="gl-mb-0">{{ $options.i18n.emptyDescription }}</p>
    </div>
    <incident-timeline-events-list
      v-if="hasTimelineEvents"
      :timeline-event-loading="timelineEventLoading"
      :timeline-events="timelineEvents"
      @hide-new-timeline-events-form="hideEventForm"
    />
    <create-timeline-event
      v-if="isEventFormVisible"
      ref="createEventForm"
      :has-timeline-events="hasTimelineEvents"
      class="timeline-event-note timeline-event-note-form"
      :class="{ 'gl-pl-0': !hasTimelineEvents }"
      @hide-new-timeline-events-form="hideEventForm"
    />
    <gl-button
      v-if="canUpdateTimelineEvent"
      variant="default"
      class="gl-mb-3 gl-mt-6"
      @click="showEventForm"
    >
      {{ $options.i18n.addEventButton }}
    </gl-button>
  </div>
</template>
