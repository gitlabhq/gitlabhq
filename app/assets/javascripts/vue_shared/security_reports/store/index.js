import Vuex from 'vuex';
import * as getters from './getters';
import state from './state';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './constants';
import sast from './modules/sast';
import secretDetection from './modules/secret_detection';

export default () =>
  new Vuex.Store({
    modules: {
      [MODULE_SAST]: sast,
      [MODULE_SECRET_DETECTION]: secretDetection,
    },
    getters,
    state,
  });
