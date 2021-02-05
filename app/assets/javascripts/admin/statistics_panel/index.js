import Vue from 'vue';
import StatisticsPanelApp from './components/app.vue';
import createStore from './store';

export default function initStatisticsPanel(el) {
  if (!el) {
    return false;
  }

  const store = createStore();

  return new Vue({
    el,
    store,
    components: {
      StatisticsPanelApp,
    },
    render(h) {
      return h(StatisticsPanelApp);
    },
  });
}
