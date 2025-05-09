import { initGroupsListWithFilteredSearch } from '~/groups/init_groups_list_with_filtered_search';
import { initYourWorkGroups } from '~/groups/your_work';
import { DASHBOARD_FILTERED_SEARCH_NAMESPACE } from '~/groups/constants';
import DashboardGroupsEmptyState from '~/groups/components/empty_states/dashboard_groups_empty_state.vue';

initGroupsListWithFilteredSearch({
  filteredSearchNamespace: DASHBOARD_FILTERED_SEARCH_NAMESPACE,
  EmptyState: DashboardGroupsEmptyState,
});
initYourWorkGroups();
