export default {
  isLoggedIn(state, getters) {
    return !!getters.getUserData.id;
  },
};
