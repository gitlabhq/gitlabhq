import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import axios from '~/lib/utils/axios_utils';
import { initializeTestTimeout } from './helpers/timeout';
import { getJSONFixture, loadHTMLFixture, setHTMLFixture } from './helpers/fixtures';

// wait for pending setTimeout()s
afterEach(() => {
  jest.runAllTimers();
});

initializeTestTimeout(300);

// fail tests for unmocked requests
beforeEach(done => {
  axios.defaults.adapter = config => {
    const error = new Error(`Unexpected unmocked request: ${JSON.stringify(config, null, 2)}`);
    error.config = config;
    done.fail(error);
    return Promise.reject(error);
  };

  done();
});

Vue.config.devtools = false;
Vue.config.productionTip = false;

Vue.use(Translate);

// workaround for JSDOM not supporting innerText
// see https://github.com/jsdom/jsdom/issues/1245
Object.defineProperty(global.Element.prototype, 'innerText', {
  get() {
    return this.textContent;
  },
  configurable: true, // make it so that it doesn't blow chunks on re-running tests with things like --watch
});

// convenience wrapper for migration from Karma
Object.assign(global, {
  loadFixtures: loadHTMLFixture,
  loadJSONFixtures: getJSONFixture,
  preloadFixtures() {},
  setFixtures: setHTMLFixture,
});
