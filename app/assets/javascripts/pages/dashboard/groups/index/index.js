import EmptyState from '~/groups/components/empty_states/groups_dashboard_empty_state.vue';
import { initGroupsListWithFilteredSearch } from '~/groups/init_groups_list_with_filtered_search';
import { DASHBOARD_FILTERED_SEARCH_NAMESPACE } from '~/groups/constants';

initGroupsListWithFilteredSearch({
  filteredSearchNamespace: DASHBOARD_FILTERED_SEARCH_NAMESPACE,
  EmptyState,
});
