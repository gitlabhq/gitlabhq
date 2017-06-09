/* global Flash */
/* eslint-disable no-param-reassign */

import service from '../services/issue_notes_service';

const state = {
  notes: [],
};

const getters = {};

const mutations = {
  setNotes(vmState, notes) {
    vmState.notes = notes;
  },
};

const actions = {
  fetchNotes(context, path) {
    return service
      .fetchNotes(path)
      .then(res => res.json())
      .then((res) => {
        context.commit('setNotes', res);
      })
      .catch(() => {
        new Flash('Something went while fetching issue comments. Please try again.'); // eslint-disable-line
      });
  },
};

export default {
  state,
  getters,
  mutations,
  actions,
};
