<script>
import { GlEmptyState, GlLoadingIcon, GlTab } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { fetchPolicies } from '~/lib/graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';
import { displayAndLogError } from './utils';

import IncidentTimelineEventsList from './timeline_events_list.vue';

export default {
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlTab,
    IncidentTimelineEventsList,
  },
  inject: ['fullPath', 'issuableId'],
  data() {
    return {
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
};
</script>

<template>
  <gl-tab :title="s__('Incident|Timeline')">
    <gl-loading-icon v-if="timelineEventLoading" size="lg" color="dark" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="showEmptyState"
      :compact="true"
      :description="s__('Incident|No timeline items have been added yet.')"
    />
    <incident-timeline-events-list
      v-if="hasTimelineEvents"
      :timeline-event-loading="timelineEventLoading"
      :timeline-events="timelineEvents"
    />
  </gl-tab>
</template>
