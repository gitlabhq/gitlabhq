<script>
import { GlTableLite, GlLink, GlEmptyState } from '@gitlab/ui';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { queryToObject, setUrlParams, visitUrl } from '~/lib/utils/url_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import KeysetPagination from '~/ml/experiment_tracking/components/pagination.vue';
import { CREATE_EXPERIMENT_HELP_PATH } from '~/ml/experiment_tracking/routes/experiments/index/constants';

import {
  LIST_KEY_CREATED_AT,
  BASE_SORT_FIELDS,
  METRIC_KEY_PREFIX,
} from '~/ml/experiment_tracking/routes/experiments/show/constants';
import * as translations from '~/ml/experiment_tracking/routes/experiments/show/translations';

export default {
  name: 'CandidateList',
  components: {
    GlTableLite,
    GlLink,
    GlEmptyState,
    TimeAgo,
    RegistrySearch,
    KeysetPagination,
  },
  props: {
    candidates: {
      type: Array,
      required: true,
    },
    metricNames: {
      type: Array,
      required: true,
    },
    paramNames: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
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
        { key: 'nameColumn', label: this.$options.i18n.NAME_LABEL },
        { key: 'created_at', label: this.$options.i18n.CREATED_AT_LABEL },
        { key: 'user', label: this.$options.i18n.USER_LABEL },
        ...this.paramNames,
        ...this.metricNames,
        { key: 'ci_job', label: this.$options.i18n.CI_JOB_LABEL },
        { key: 'artifact', label: this.$options.i18n.ARTIFACTS_LABEL },
      ];
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
    tableItems() {
      return this.candidates.map((candidate) => ({
        ...candidate,
        nameColumn: {
          name: candidate.name,
          details_path: candidate.details,
        },
      }));
    },
    hasItems() {
      return this.candidates.length > 0;
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
    ...translations,
  },
  constants: {
    CREATE_EXPERIMENT_HELP_PATH,
  },
};
</script>

<template>
  <section>
    <registry-search
      :filters="filters"
      :sorting="sorting"
      :sortable-fields="sortableFields"
      @sorting:changed="updateSortingAndEmitUpdate"
      @filter:changed="updateFilters"
      @filter:submit="submitFilters"
      @filter:clear="filters = []"
    />

    <div v-if="hasItems" class="gl-overflow-x-auto">
      <gl-table-lite
        :fields="fields"
        :items="tableItems"
        show-empty
        small
        class="ml-candidate-table !gl-mt-0"
      >
        <template #cell()="data">
          <div>{{ data.value }}</div>
        </template>

        <template #cell(nameColumn)="data">
          <gl-link :href="data.value.details_path">
            <span v-if="data.value.name"> {{ data.value.name }}</span>
            <span v-else class="gl-italic">{{ $options.i18n.NO_CANDIDATE_NAME }}</span>
          </gl-link>
        </template>

        <template #cell(artifact)="data">
          <gl-link v-if="data.value" :href="data.value" target="_blank">{{
            $options.i18n.ARTIFACTS_LABEL
          }}</gl-link>
          <div v-else class="gl-italic gl-text-subtle">
            {{ $options.i18n.NO_ARTIFACT }}
          </div>
        </template>

        <template #cell(created_at)="data">
          <time-ago :time="data.value" />
        </template>

        <template #cell(user)="data">
          <gl-link v-if="data.value" :href="data.value.path">@{{ data.value.username }}</gl-link>
          <div v-else>{{ $options.i18n.NO_DATA_CONTENT }}</div>
        </template>

        <template #cell(ci_job)="data">
          <gl-link v-if="data.value" :href="data.value.path" target="_blank">{{
            data.value.name
          }}</gl-link>
          <div v-else class="gl-italic gl-text-subtle">
            {{ $options.i18n.NO_JOB }}
          </div>
        </template>
      </gl-table-lite>
    </div>

    <gl-empty-state
      v-else
      :title="$options.i18n.EMPTY_STATE_TITLE_LABEL"
      :primary-button-text="$options.i18n.CREATE_NEW_LABEL"
      :primary-button-link="$options.constants.CREATE_EXPERIMENT_HELP_PATH"
      :svg-path="emptyStateSvgPath"
      :svg-height="null"
      :description="$options.i18n.EMPTY_STATE_DESCRIPTION_LABEL"
      class="gl-py-8"
    />

    <keyset-pagination v-if="hasItems" v-bind="pageInfo" />
  </section>
</template>
