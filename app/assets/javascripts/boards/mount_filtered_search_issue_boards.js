import Vue from 'vue';
import IssueBoardFilteredSearch from '~/boards/components/issue_board_filtered_search.vue';
import store from '~/boards/stores';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';

export default (apolloProvider) => {
  const el = document.getElementById('js-issue-board-filtered-search');
  const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });

  const initialFilterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams, {}),
  };

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    provide: {
      initialFilterParams,
    },
    store, // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/324094
    apolloProvider,
    render: (createElement) =>
      createElement(IssueBoardFilteredSearch, {
        props: { fullPath: store.state?.fullPath || '', boardType: store.state?.boardType || '' },
      }),
  });
};
