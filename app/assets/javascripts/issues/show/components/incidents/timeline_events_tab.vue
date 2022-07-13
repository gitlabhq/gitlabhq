<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlTab } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { fetchPolicies } from '~/lib/graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';
import { displayAndLogError } from './utils';
import { timelineTabI18n } from './constants';

import IncidentTimelineEventForm from './timeline_events_form.vue';
import IncidentTimelineEventsList from './timeline_events_list.vue';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    GlTab,
    IncidentTimelineEventForm,
    IncidentTimelineEventsList,
  },
  i18n: timelineTabI18n,
  inject: ['canUpdate', 'fullPath', 'issuableId'],
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
          incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
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
  methods: {
    hideEventForm() {
      this.isEventFormVisible = false;
    },
    async showEventForm() {
      this.isEventFormVisible = true;
      await this.$nextTick();
      this.$refs.eventForm.focusDate();
    },
  },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <gl-loading-icon v-if="timelineEventLoading" size="lg" color="dark" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="showEmptyState"
      :compact="true"
      :description="$options.i18n.emptyDescription"
    />
    <incident-timeline-events-list
      v-if="hasTimelineEvents"
      :timeline-event-loading="timelineEventLoading"
      :timeline-events="timelineEvents"
    />
    <incident-timeline-event-form
      v-show="isEventFormVisible"
      ref="eventForm"
      :has-timeline-events="hasTimelineEvents"
      class="timeline-event-note timeline-event-note-form"
      :class="{ 'gl-pl-0': !hasTimelineEvents }"
      @hide-incident-timeline-event-form="hideEventForm"
    />
    <gl-button v-if="canUpdate" variant="default" class="gl-mb-3 gl-mt-7" @click="showEventForm">
      {{ $options.i18n.addEventButton }}
    </gl-button>
  </gl-tab>
</template>
