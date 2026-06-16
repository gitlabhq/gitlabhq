<script>
import GroupsDropdownFilter from '~/analytics/shared/components/groups_dropdown_filter.vue';
import { getParameterByName } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import GetDefaultGroupsQuery from './get_default_groups.query.graphql';
import { GROUP_FILTER_QUERY_NAME } from './constants';

export default {
  name: 'AnalyticsDashboardGroupFilter',
  components: {
    GroupsDropdownFilter,
  },
  props: {
    multiSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['group-selected'],
  data() {
    return {
      defaultGroups: [],
    };
  },
  apollo: {
    defaultGroups: {
      query: GetDefaultGroupsQuery,
      variables() {
        return { ids: this.defaultGroupIds };
      },
      update({ groups }) {
        return groups?.nodes || [];
      },
      skip() {
        return this.defaultGroupIds.length === 0;
      },
    },
  },
  computed: {
    defaultGroupIds() {
      let allGroups =
        getParameterByName(GROUP_FILTER_QUERY_NAME, window.location.search, {
          gatherArrays: true,
        }) || [];

      // Handles the case where the query param doesn't include the `[]` suffix
      if (!Array.isArray(allGroups)) {
        allGroups = [allGroups];
      }

      allGroups = allGroups.map((id) => convertToGraphQLId(TYPENAME_GROUP, id));

      return this.multiSelect ? allGroups : allGroups.slice(0, 1);
    },
    isLoadingDefaultGroups() {
      return this.$apollo.queries.defaultGroups.loading;
    },
  },
  methods: {
    onGroupsSelected(selectedGroups) {
      this.$emit('group-selected', selectedGroups);
    },
  },
  queryParams: {
    first: 50,
    includeSubgroups: true,
  },
};
</script>

<template>
  <groups-dropdown-filter
    toggle-classes="gl-max-w-26"
    :query-params="$options.queryParams"
    :multi-select="multiSelect"
    :loading-default-groups="isLoadingDefaultGroups"
    :default-groups="defaultGroups"
    @selected="onGroupsSelected"
  />
</template>
