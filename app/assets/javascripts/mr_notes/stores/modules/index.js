import * as actions from '../actions';
import getters from '../getters';
import mutations from '../mutations';

export default () => ({
  state: {
    endpoints: {},
    activeTab: null,
    mrMetadata: {},
    failedToLoadMetadata: false,
  },
  actions,
  getters,
  mutations,
});
