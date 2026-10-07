import * as types from './mutation_types';

export default {
  [types.SET_LOADING_STATE](state, value) {
    state.loading = value;
  },
  [types.SET_STATS_LOADING_STATE](state, value) {
    state.statsLoading = value;
  },
  [types.SET_CHART_DATA](state, chartData) {
    Object.assign(state, {
      chartData,
      statsLoaded: false,
    });
  },
  [types.SET_CHART_STATS](state, chartStats) {
    const statsByCommitId = Object.fromEntries(
      chartStats
        .filter(({ id }) => id)
        .map(({ id, additions, deletions }) => [id, { additions, deletions }]),
    );

    Object.assign(state, {
      chartData: (state.chartData || []).map((commit) => ({
        ...commit,
        ...(statsByCommitId[commit.id] || {}),
      })),
      statsLoaded: true,
    });
  },
  [types.SET_ACTIVE_BRANCH](state, branch) {
    Object.assign(state, {
      branch,
    });
  },
};
