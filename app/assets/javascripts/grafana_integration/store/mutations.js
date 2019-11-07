import * as types from './mutation_types';

export default {
  [types.SET_GRAFANA_URL](state, url) {
    state.grafanaUrl = url;
  },
  [types.SET_GRAFANA_TOKEN](state, token) {
    state.grafanaToken = token;
  },
  [types.SET_GRAFANA_ENABLED](state, enabled) {
    state.grafanaEnabled = enabled;
  },
};
