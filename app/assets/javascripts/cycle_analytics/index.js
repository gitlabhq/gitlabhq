import Vue from 'vue';
import Translate from '../vue_shared/translate';
import CycleAnalytics from './components/base.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const store = createStore();
  const el = document.querySelector('#js-cycle-analytics');
  const {
    noAccessSvgPath,
    noDataSvgPath,
    requestPath,
    fullPath,
    projectId,
    groupPath,
  } = el.dataset;

  store.dispatch('initializeVsa', {
    projectId: parseInt(projectId, 10),
    groupPath,
    endpoints: {
      requestPath,
      fullPath,
    },
    features: {
      cycleAnalyticsForGroups: Boolean(gon?.licensed_features?.cycleAnalyticsForGroups),
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CycleAnalytics',
    store,
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          noDataSvgPath,
          noAccessSvgPath,
          fullPath,
        },
      }),
  });
};
