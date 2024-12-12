import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  extractFilterQueryParameters,
  extractPaginationQueryParameters,
} from '~/analytics/shared/utils';
import Translate from '~/vue_shared/translate';
import { defaultClient } from '~/analytics/shared/graphql/client';
import { parseBoolean } from '~/lib/utils/common_utils';
import CycleAnalytics from './components/base.vue';
import createStore from './store';
import { buildCycleAnalyticsInitialData } from './utils';

Vue.use(Translate);
Vue.use(VueApollo);

export default () => {
  const store = createStore();
  const el = document.querySelector('#js-cycle-analytics');
  const { noAccessSvgPath, noDataSvgPath, hasScopedLabelsFeature } = el.dataset;
  const initialData = buildCycleAnalyticsInitialData({ ...el.dataset, gon });

  const pagination = extractPaginationQueryParameters(window.location.search);
  const { selectedAuthor, selectedMilestone, selectedAssigneeList, selectedLabelList } =
    extractFilterQueryParameters(window.location.search);

  store.dispatch('initializeVsa', {
    ...initialData,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    pagination,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CycleAnalytics',
    apolloProvider: new VueApollo({ defaultClient }),
    provide: {
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
    },
    store,
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          noDataSvgPath,
          noAccessSvgPath,
        },
      }),
  });
};
