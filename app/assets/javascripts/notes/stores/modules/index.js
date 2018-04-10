import * as actions from '../actions';
import * as getters from '../getters';
import mutations from '../mutations';

export default {
  state: {
    notes: [],
    targetNoteHash: null,
    lastFetchedAt: null,

    // View layer
    isToggleStateButtonLoading: false,

    // holds endpoints and permissions provided through haml
    notesData: {
      markdownDocsPath: '',
    },
    userData: {},
    noteableData: {},
  },
  actions,
  getters,
  mutations,
};
