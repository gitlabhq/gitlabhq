// Note: this getter is important because
// `noteableData` is namespaced under `notes` for `~/mr_notes/stores`
// while `noteableData` is directly available as `state.noteableData` for `~/notes/stores`
export const getNoteableData = (state) => state.notes.noteableData;

export default {
  isLoggedIn(state, getters) {
    return Boolean(getters.getUserData.id);
  },
  isDiffsPage(state) {
    return state.activeTab === 'diffs';
  },
  allVisibleDiscussionsExpanded(state, getters) {
    if (getters.isDiffsPage) return getters['diffs/allDiffDiscussionsExpanded'];
    return getters.allDiscussionsExpanded;
  },
};
