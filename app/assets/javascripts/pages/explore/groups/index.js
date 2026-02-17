if (gon.features.exploreGroupsVue) {
  // eslint-disable-next-line promise/catch-or-return
  import('~/explore/groups').then(({ initExploreGroups }) => {
    initExploreGroups();
  });
} else {
  // eslint-disable-next-line promise/catch-or-return
  Promise.all([
    import('~/groups/init_groups_list_with_filtered_search'),
    import('~/groups/components/empty_states/groups_explore_empty_state.vue'),
    import('~/groups/constants'),
  ]).then(([{ initGroupsListWithFilteredSearch }, EmptyStateModule, constantsModule]) => {
    initGroupsListWithFilteredSearch({
      filteredSearchNamespace: constantsModule.EXPLORE_FILTERED_SEARCH_NAMESPACE,
      EmptyState: EmptyStateModule.default,
    });
  });
}
