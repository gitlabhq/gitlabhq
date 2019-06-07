export default {
  isLoggedIn(state, getters) {
    return Boolean(getters.getUserData.id);
  },
};
