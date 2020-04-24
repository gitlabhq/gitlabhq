import * as types from './mutation_types';

export const setAlerts = ({ commit }, alerts) => {
  commit(types.SET_ALERTS, alerts);
};

export const setLoading = ({ commit }, loading) => {
  commit(types.SET_LOADING, loading);
};
