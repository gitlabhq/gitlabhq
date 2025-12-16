<script>
import { GlEmptyState, GlKeysetPagination, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg?url';
import { DEFAULT_PER_PAGE } from '~/api';
import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import {
  CONTRIBUTION_TYPE_FILTER_TYPE,
  RECENT_SEARCHES_STORAGE_KEY,
  FILTERED_SEARCH_NAMESPACE,
  convertTokensToFilter,
} from '../filters';

export default {
  name: 'OrganizationsActivityApp',
  i18n: {
    emptyStateTitle: __('No activities found'),
    eventsErrorMessage: s__(
      'Organization|An error occurred loading the activity. Please refresh the page to try again.',
    ),
    contributionType: __('Contribution type'),
  },
  components: {
    FilteredSearch,
    ContributionEvents,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
  },
  props: {
    organizationActivityPath: {
      type: String,
      required: true,
    },
    organizationActivityEventTypes: {
      type: Array,
      required: true,
    },
    organizationActivityAllEvent: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      events: [],
      eventsLoading: false,
      eventFilter: this.organizationActivityAllEvent,
      hasNextPage: false,
      hasPreviousPage: false,
      currentOffset: 0,
    };
  },
  computed: {
    showEmptyState() {
      return !this.eventsLoading && !this.events.length;
    },
    paginationInfo() {
      return {
        hasNextPage: this.hasNextPage,
        hasPreviousPage: this.hasPreviousPage,
      };
    },
    availableTokens() {
      return [
        {
          title: this.$options.i18n.contributionType,
          icon: 'comparison',
          type: CONTRIBUTION_TYPE_FILTER_TYPE,
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: this.organizationActivityEventTypes,
        },
      ];
    },
  },
  async mounted() {
    this.fetchEvents();
  },
  methods: {
    onSearchFilter(tokens) {
      this.eventFilter = convertTokensToFilter(tokens) || this.organizationActivityAllEvent;
      this.currentOffset = 0;
      this.hasPreviousPage = false;
      this.fetchEvents();
    },
    async fetchEvents(offset = 0) {
      this.eventsLoading = true;

      try {
        const {
          data: { events, has_next_page: hasNextPage },
        } = await axios.get(this.organizationActivityPath, {
          params: {
            offset,
            limit: DEFAULT_PER_PAGE,
            event_filter: this.eventFilter,
          },
        });

        this.hasNextPage = hasNextPage;
        this.hasPreviousPage = offset > 0;
        this.currentOffset = offset;
        this.events = events;
      } catch (error) {
        createAlert({ message: this.$options.i18n.eventsErrorMessage, error, captureError: true });
      } finally {
        this.eventsLoading = false;
      }
    },
    handleNextPage() {
      const nextOffset = this.currentOffset + DEFAULT_PER_PAGE;
      this.fetchEvents(nextOffset);
    },
    handlePrevPage() {
      const prevOffset = Math.max(0, this.currentOffset - DEFAULT_PER_PAGE);
      this.fetchEvents(prevOffset);
    },
  },
  EMPTY_STATE_SVG_URL,
  RECENT_SEARCHES_STORAGE_KEY,
  FILTERED_SEARCH_NAMESPACE,
};
</script>

<template>
  <div>
    <filtered-search
      :recent-searches-storage-key="$options.RECENT_SEARCHES_STORAGE_KEY"
      :namespace="$options.FILTERED_SEARCH_NAMESPACE"
      :tokens="availableTokens"
      terms-as-tokens
      @onFilter="onSearchFilter"
    />

    <template v-if="!showEmptyState">
      <contribution-events :events="events" />
      <gl-loading-icon v-if="eventsLoading" size="md" class="gl-mb-3" />
      <gl-keyset-pagination
        v-else
        v-bind="paginationInfo"
        class="gl-my-6 gl-flex gl-justify-center"
        @prev="handlePrevPage"
        @next="handleNextPage"
      />
    </template>

    <gl-empty-state
      v-else-if="showEmptyState"
      :title="$options.i18n.emptyStateTitle"
      :svg-path="$options.EMPTY_STATE_SVG_URL"
    />
  </div>
</template>
