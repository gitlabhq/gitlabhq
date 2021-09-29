import Vue from 'vue';
import Translate from '../vue_shared/translate';
import CycleAnalytics from './components/base.vue';
import { DEFAULT_DAYS_TO_DISPLAY } from './constants';
import createStore from './store';
import { calculateFormattedDayInPast } from './utils';

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
    groupId,
    groupPath,
    labelsPath,
    milestonesPath,
  } = el.dataset;

  const { now, past } = calculateFormattedDayInPast(DEFAULT_DAYS_TO_DISPLAY);

  store.dispatch('initializeVsa', {
    projectId: parseInt(projectId, 10),
    endpoints: {
      requestPath,
      fullPath,
      labelsPath,
      milestonesPath,
      groupId: parseInt(groupId, 10),
      groupPath,
    },
    features: {
      cycleAnalyticsForGroups: Boolean(gon?.licensed_features?.cycleAnalyticsForGroups),
    },
    createdBefore: new Date(now),
    createdAfter: new Date(past),
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CycleAnalytics',
    apolloProvider: {},
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
