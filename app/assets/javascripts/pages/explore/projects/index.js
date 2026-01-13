if (gon.features.exploreProjectsVue) {
  // eslint-disable-next-line promise/catch-or-return
  import('~/explore/projects').then(({ initExploreProjects }) => {
    initExploreProjects();
  });
} else {
  // eslint-disable-next-line promise/catch-or-return
  import('~/projects/filtered_search_and_sort').then(({ initProjectsFilteredSearchAndSort }) => {
    initProjectsFilteredSearchAndSort({
      sortEventName: 'use_sort_projects_explore',
      filterEventName: 'use_filter_bar_projects_explore',
    });
  });
}
