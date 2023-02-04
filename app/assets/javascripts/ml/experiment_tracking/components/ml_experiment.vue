<script>
import { GlTable, GlLink, GlTooltipDirective } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  LIST_KEY_CREATED_AT,
  BASE_SORT_FIELDS,
  METRIC_KEY_PREFIX,
  FEATURE_NAME,
  FEATURE_FEEDBACK_ISSUE,
} from '~/ml/experiment_tracking/constants';
import { s__ } from '~/locale';
import { queryToObject, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import KeysetPagination from '~/vue_shared/components/incubation/pagination.vue';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';

export default {
  name: 'MlExperiment',
  components: {
    GlTable,
    GlLink,
    TimeAgo,
    IncubationAlert,
    RegistrySearch,
    KeysetPagination,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['candidates', 'metricNames', 'paramNames', 'pageInfo'],
  data() {
    const query = queryToObject(window.location.search);

    const filter = query.name ? [{ value: { data: query.name }, type: FILTERED_SEARCH_TERM }] : [];

    let orderBy = query.orderBy || LIST_KEY_CREATED_AT;

    if (query.orderByType === 'metric') {
      orderBy = `${METRIC_KEY_PREFIX}${orderBy}`;
    }

    return {
      filters: filter,
      sorting: {
        orderBy,
        sort: (query.sort || 'desc').toLowerCase(),
      },
    };
  },
  computed: {
    fields() {
      if (this.candidates.length === 0) return [];

      return [
        { key: 'name', label: this.$options.i18n.nameLabel },
        { key: 'created_at', label: this.$options.i18n.createdAtLabel },
        { key: 'user', label: this.$options.i18n.userLabel },
        ...this.paramNames,
        ...this.metricNames,
        { key: 'details', label: '' },
        { key: 'artifact', label: '' },
      ];
    },
    displayPagination() {
      return this.candidates.length > 0;
    },
    sortableFields() {
      return [
        ...BASE_SORT_FIELDS,
        ...this.metricNames.map((name) => ({
          orderBy: `${METRIC_KEY_PREFIX}${name}`,
          label: capitalizeFirstCharacter(name),
        })),
      ];
    },
    parsedQuery() {
      const name = this.filters
        .map((f) => f.value.data)
        .join(' ')
        .trim();

      const filterByQuery = name === '' ? {} : { name };

      let orderByType = 'column';
      let { orderBy } = this.sorting;
      const { sort } = this.sorting;

      if (orderBy.startsWith(METRIC_KEY_PREFIX)) {
        orderBy = this.sorting.orderBy.slice(METRIC_KEY_PREFIX.length);
        orderByType = 'metric';
      }

      return { ...filterByQuery, orderBy, orderByType, sort };
    },
  },
  methods: {
    submitFilters() {
      return visitUrl(setUrlParams({ ...this.parsedQuery }));
    },
    updateFilters(newValue) {
      this.filters = newValue;
    },
    updateSorting(newValue) {
      this.sorting = { ...this.sorting, ...newValue };
    },
    updateSortingAndEmitUpdate(newValue) {
      this.updateSorting(newValue);
      this.submitFilters();
    },
  },
  i18n: {
    titleLabel: s__('MlExperimentTracking|Experiment candidates'),
    emptyStateLabel: s__('MlExperimentTracking|No candidates to display'),
    artifactsLabel: s__('MlExperimentTracking|Artifacts'),
    detailsLabel: s__('MlExperimentTracking|Details'),
    userLabel: s__('MlExperimentTracking|User'),
    createdAtLabel: s__('MlExperimentTracking|Created at'),
    nameLabel: s__('MlExperimentTracking|Name'),
    noDataContent: s__('MlExperimentTracking|-'),
    filterCandidatesLabel: s__('MlExperimentTracking|Filter candidates'),
  },
  FEATURE_NAME,
  FEATURE_FEEDBACK_ISSUE,
};
</script>

<template>
  <div>
    <incubation-alert
      :feature-name="$options.FEATURE_NAME"
      :link-to-feedback-issue="$options.FEATURE_FEEDBACK_ISSUE"
    />

    <h3>
      {{ $options.i18n.titleLabel }}
    </h3>

    <registry-search
      :filters="filters"
      :sorting="sorting"
      :sortable-fields="sortableFields"
      @sorting:changed="updateSortingAndEmitUpdate"
      @filter:changed="updateFilters"
      @filter:submit="submitFilters"
      @filter:clear="filters = []"
    />

    <gl-table
      :fields="fields"
      :items="candidates"
      :empty-text="$options.i18n.emptyStateLabel"
      show-empty
      small
      class="gl-mt-0! ml-candidate-table"
    >
      <template #cell()="data">
        <div v-gl-tooltip.hover :title="data.value">{{ data.value }}</div>
      </template>

      <template #cell(artifact)="data">
        <gl-link
          v-if="data.value"
          v-gl-tooltip.hover
          :href="data.value"
          target="_blank"
          :title="$options.i18n.artifactsLabel"
          >{{ $options.i18n.artifactsLabel }}</gl-link
        >
        <div v-else v-gl-tooltip.hover :title="$options.i18n.artifactsLabel">
          {{ $options.i18n.noDataContent }}
        </div>
      </template>

      <template #cell(details)="data">
        <gl-link v-gl-tooltip.hover :href="data.value" :title="$options.i18n.detailsLabel">{{
          $options.i18n.detailsLabel
        }}</gl-link>
      </template>

      <template #cell(created_at)="data">
        <time-ago v-gl-tooltip.hover :time="data.value" :title="data.value" />
      </template>

      <template #cell(user)="data">
        <gl-link
          v-if="data.value"
          v-gl-tooltip.hover
          :href="data.value.path"
          :title="data.value.username"
          >@{{ data.value.username }}</gl-link
        >
        <div v-else>{{ $options.i18n.noDataContent }}</div>
      </template>
    </gl-table>

    <keyset-pagination v-if="displayPagination" v-bind="pageInfo" />
  </div>
</template>
