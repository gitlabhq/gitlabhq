/**
 * While we are in the process implementing group level features at the project level
 * we will use a simplified vuex store for the project level, eventually this can be
 * replaced with the store at ee/app/assets/javascripts/analytics/cycle_analytics/store/index.js
 * once we have enough of the same features implemented across the project and group level
 */

import Vue from 'vue';
import Vuex from 'vuex';
import filters from '~/vue_shared/components/filtered_search_bar/store/modules/filters';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state,
    modules: { filters },
  });
