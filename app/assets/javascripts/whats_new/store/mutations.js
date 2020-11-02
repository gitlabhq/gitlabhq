import * as types from './mutation_types';

export default {
  [types.CLOSE_DRAWER](state) {
    state.open = false;
  },
  [types.OPEN_DRAWER](state) {
    state.open = true;
  },
  [types.ADD_FEATURES](state, data) {
    state.features = state.features.concat(data);
  },
  [types.SET_PAGE_INFO](state, pageInfo) {
    state.pageInfo = pageInfo;
  },
  [types.SET_FETCHING](state, fetching) {
    state.fetching = fetching;
  },
  [types.SET_DRAWER_BODY_HEIGHT](state, height) {
    state.drawerBodyHeight = height;
  },
};
