import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import branches from './modules/branches';
import commitModule from './modules/commit';
import editorModule from './modules/editor';
import { setupFileEditorsSync } from './modules/editor/setup';
import fileTemplates from './modules/file_templates';
import mergeRequests from './modules/merge_requests';
import paneModule from './modules/pane';
import pipelines from './modules/pipelines';
import routerModule from './modules/router';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const createStoreOptions = () => ({
  state: state(),
  actions,
  mutations,
  getters,
  modules: {
    commit: commitModule,
    pipelines,
    mergeRequests,
    branches,
    fileTemplates: fileTemplates(),
    rightPane: paneModule(),
    router: routerModule,
    editor: editorModule,
  },
});

export const createStore = () => {
  const store = new Vuex.Store(createStoreOptions());

  setupFileEditorsSync(store);

  return store;
};
