<script>
import { GlEmptyState, GlPagination, GlLoadingIcon, GlFilteredSearchToken } from '@gitlab/ui';
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
    GlPagination,
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
      page: 1,
      eventFilter: this.organizationActivityAllEvent,
      hasNextPage: false,
    };
  },
  computed: {
    showEmptyState() {
      return !this.eventsLoading && !this.events.length;
    },
    nextPage() {
      // next-page prop expects number or undefined
      return this.hasNextPage ? this.page + 1 : undefined;
    },
    prevPage() {
      return this.page - 1;
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
    calculateOffset(page) {
      // Offset is starts at 0, but pages start at page 1.  We need to use -1 logic to generate offset
      return (page - 1) * DEFAULT_PER_PAGE;
    },
    onSearchFilter(tokens) {
      this.eventFilter = convertTokensToFilter(tokens) || this.organizationActivityAllEvent;
      this.fetchEvents();
    },
    async fetchEvents(page = 1) {
      this.eventsLoading = true;

      try {
        const {
          data: { events, has_next_page: hasNextPage },
        } = await axios.get(this.organizationActivityPath, {
          params: {
            offset: this.calculateOffset(page),
            limit: DEFAULT_PER_PAGE,
            event_filter: this.eventFilter,
          },
        });

        this.hasNextPage = hasNextPage;
        this.events = events;
        this.page = page;
      } catch (error) {
        createAlert({ message: this.$options.i18n.eventsErrorMessage, error, captureError: true });
      } finally {
        this.eventsLoading = false;
      }
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
      <gl-pagination
        v-else
        :value="page"
        :prev-page="prevPage"
        :next-page="nextPage"
        align="center"
        class="gl-w-full"
        @input="fetchEvents"
      />
    </template>

    <gl-empty-state
      v-else-if="showEmptyState"
      :title="$options.i18n.emptyStateTitle"
      :svg-path="$options.EMPTY_STATE_SVG_URL"
    />
  </div>
</template>
