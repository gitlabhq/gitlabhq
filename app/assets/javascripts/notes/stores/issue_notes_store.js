/* global Flash */
/* eslint-disable no-param-reassign */

import service from '../services/issue_notes_service';

const state = {
  notes: [],
};

const getters = {
  notes(storeState) {
    return storeState.notes;
  },
};

const mutations = {
  setNotes(storeState, notes) {
    storeState.notes = notes;
  },
  toggleDiscussion(storeState, { discussionId }) {
    const [discussion] = storeState.notes.filter(note => note.id === discussionId);

    discussion.expanded = !discussion.expanded;
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
        new Flash('Something went wrong while fetching issue comments. Please try again.'); // eslint-disable-line
      });
  },
};

export default {
  state,
  getters,
  mutations,
  actions,
};
