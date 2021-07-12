<script>
import { cloneDeep } from 'lodash';
import { formatNumber, sprintf, __, s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import {
  STATUS_ACTIVE,
  STATUS_PAUSED,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_NOT_CONNECTED,
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  CREATED_DESC,
  CREATED_ASC,
  CONTACTED_DESC,
  CONTACTED_ASC,
  PARAM_KEY_STATUS,
  PARAM_KEY_RUNNER_TYPE,
  PARAM_KEY_TAG,
} from '../constants';
import TagToken from './search_tokens/tag_token.vue';

const sortOptions = [
  {
    id: 1,
    title: __('Created date'),
    sortDirection: {
      descending: CREATED_DESC,
      ascending: CREATED_ASC,
    },
  },
  {
    id: 2,
    title: __('Last contact'),
    sortDirection: {
      descending: CONTACTED_DESC,
      ascending: CONTACTED_ASC,
    },
  },
];

export default {
  components: {
    FilteredSearch,
  },
  props: {
    value: {
      type: Object,
      required: true,
      validator(val) {
        return Array.isArray(val?.filters) && typeof val?.sort === 'string';
      },
    },
    namespace: {
      type: String,
      required: true,
    },
    activeRunnersCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    // filtered_search_bar_root.vue may mutate the inital
    // filters. Use `cloneDeep` to prevent those mutations
    //  from affecting this component
    const { filters, sort } = cloneDeep(this.value);
    return {
      initialFilterValue: filters,
      initialSortBy: sort,
    };
  },
  computed: {
    searchTokens() {
      return [
        {
          icon: 'status',
          title: __('Status'),
          type: PARAM_KEY_STATUS,
          token: BaseToken,
          unique: true,
          options: [
            { value: STATUS_ACTIVE, title: s__('Runners|Active') },
            { value: STATUS_PAUSED, title: s__('Runners|Paused') },
            { value: STATUS_ONLINE, title: s__('Runners|Online') },
            { value: STATUS_OFFLINE, title: s__('Runners|Offline') },

            // Added extra quotes in this title to avoid splitting this value:
            // see: https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1438
            { value: STATUS_NOT_CONNECTED, title: `"${s__('Runners|Not connected')}"` },
          ],
          // TODO In principle we could support more complex search rules,
          // this can be added to a separate issue.
          operators: OPERATOR_IS_ONLY,
        },

        {
          icon: 'file-tree',
          title: __('Type'),
          type: PARAM_KEY_RUNNER_TYPE,
          token: BaseToken,
          unique: true,
          options: [
            { value: INSTANCE_TYPE, title: s__('Runners|instance') },
            { value: GROUP_TYPE, title: s__('Runners|group') },
            { value: PROJECT_TYPE, title: s__('Runners|project') },
          ],
          // TODO We should support more complex search rules,
          // search for multiple states (OR) or have NOT operators
          operators: OPERATOR_IS_ONLY,
        },

        {
          icon: 'tag',
          title: s__('Runners|Tags'),
          type: PARAM_KEY_TAG,
          token: TagToken,
          recentTokenValuesStorageKey: `${this.namespace}-recent-tags`,
          operators: OPERATOR_IS_ONLY,
        },
      ];
    },
    activeRunnersMessage() {
      return sprintf(__('Runners currently online: %{active_runners_count}'), {
        active_runners_count: formatNumber(this.activeRunnersCount),
      });
    },
  },
  methods: {
    onFilter(filters) {
      const { sort } = this.value;

      this.$emit('input', {
        filters,
        sort,
        pagination: { page: 1 },
      });
    },
    onSort(sort) {
      const { filters } = this.value;

      this.$emit('input', {
        filters,
        sort,
        pagination: { page: 1 },
      });
    },
  },
  sortOptions,
};
</script>
<template>
  <div>
    <filtered-search
      v-bind="$attrs"
      :namespace="namespace"
      recent-searches-storage-key="runners-search"
      :sort-options="$options.sortOptions"
      :initial-filter-value="initialFilterValue"
      :initial-sort-by="initialSortBy"
      :tokens="searchTokens"
      :search-input-placeholder="__('Search or filter results...')"
      data-testid="runners-filtered-search"
      @onFilter="onFilter"
      @onSort="onSort"
    />
    <div class="gl-text-right" data-testid="active-runners-message">{{ activeRunnersMessage }}</div>
  </div>
</template>
