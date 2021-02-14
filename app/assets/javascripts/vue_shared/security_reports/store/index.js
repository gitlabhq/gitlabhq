import Vuex from 'vuex';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './constants';
import * as getters from './getters';
import sast from './modules/sast';
import secretDetection from './modules/secret_detection';
import state from './state';

export default () =>
  new Vuex.Store({
    modules: {
      [MODULE_SAST]: sast,
      [MODULE_SECRET_DETECTION]: secretDetection,
    },
    getters,
    state,
  });
