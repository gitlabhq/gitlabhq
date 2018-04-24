import Vue from 'vue';

import Translate from '~/vue_shared/translate';

import { getTimeframeWindow } from '~/lib/utils/datetime_utility';

import { TIMEFRAME_LENGTH } from './constants';

import RoadmapStore from './store/roadmap_store';
import RoadmapService from './service/roadmap_service';

import roadmapApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-roadmap');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      roadmapApp,
    },
    data() {
      const dataset = this.$options.el.dataset;
      const filterQueryString = window.location.search.substring(1);

      // Construct Epic API path to include
      // `start_date` & `end_date` query params to get list of
      // epics only for current timeframe.
      const timeframe = getTimeframeWindow(TIMEFRAME_LENGTH);
      const start = timeframe[0];
      const end = timeframe[TIMEFRAME_LENGTH - 1];
      const startDate = `${start.getFullYear()}-${start.getMonth() + 1}-${start.getDate()}`;
      const endDate = `${end.getFullYear()}-${end.getMonth() + 1}-${end.getDate()}`;
      let epicsPath = `${dataset.epicsPath}?start_date=${startDate}&end_date=${endDate}`;

      if (filterQueryString) {
        epicsPath += `&${filterQueryString}`;
      }

      const store = new RoadmapStore(parseInt(dataset.groupId, 0), timeframe);
      const service = new RoadmapService(epicsPath);

      return {
        store,
        service,
        emptyStateIllustrationPath: dataset.emptyStateIllustration,
      };
    },
    render(createElement) {
      return createElement('roadmap-app', {
        props: {
          store: this.store,
          service: this.service,
          emptyStateIllustrationPath: this.emptyStateIllustrationPath,
        },
      });
    },
  });
};
