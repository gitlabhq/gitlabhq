import Vue from 'vue';
import * as jqueryMatchers from 'custom-jquery-matchers';
import $ from 'jquery';
import { config as testUtilsConfig } from '@vue/test-utils';
import Translate from '~/vue_shared/translate';
import { initializeTestTimeout } from './helpers/timeout';
import { getJSONFixture, loadHTMLFixture, setHTMLFixture } from './helpers/fixtures';
import { setupManualMocks } from './mocks/mocks_helper';
import customMatchers from './matchers';

import './helpers/dom_shims';

// Expose jQuery so specs using jQuery plugins can be imported nicely.
// Here is an issue to explore better alternatives:
// https://gitlab.com/gitlab-org/gitlab/issues/12448
window.jQuery = $;

process.on('unhandledRejection', global.promiseRejectionHandler);

setupManualMocks();

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runAllTimers();
  }),
);

initializeTestTimeout(process.env.CI ? 5000 : 500);

Vue.config.devtools = false;
Vue.config.productionTip = false;

Vue.use(Translate);

// workaround for JSDOM not supporting innerText
// see https://github.com/jsdom/jsdom/issues/1245
Object.defineProperty(global.Element.prototype, 'innerText', {
  get() {
    return this.textContent;
  },
  set(value) {
    this.textContext = value;
  },
  configurable: true, // make it so that it doesn't blow chunks on re-running tests with things like --watch
});

// convenience wrapper for migration from Karma
Object.assign(global, {
  getJSONFixture,
  loadFixtures: loadHTMLFixture,
  setFixtures: setHTMLFixture,

  // The following functions fill the fixtures cache in Karma.
  // This is not necessary in Jest because we make no Ajax request.
  loadJSONFixtures() {},
  preloadFixtures() {},
});

Object.assign(global, {
  MutationObserver() {
    return {
      disconnect() {},
      observe() {},
    };
  },
});

// custom-jquery-matchers was written for an old Jest version, we need to make it compatible
Object.entries(jqueryMatchers).forEach(([matcherName, matcherFactory]) => {
  expect.extend({
    [matcherName]: matcherFactory().compare,
  });
});

expect.extend(customMatchers);

// Tech debt issue TBD
testUtilsConfig.logModifiedComponents = false;

// Basic stub for MutationObserver
global.MutationObserver = () => ({
  disconnect: () => {},
  observe: () => {},
});

Object.assign(global, {
  requestIdleCallback(cb) {
    const start = Date.now();
    return setTimeout(() => {
      cb({
        didTimeout: false,
        timeRemaining: () => Math.max(0, 50 - (Date.now() - start)),
      });
    });
  },
  cancelIdleCallback(id) {
    clearTimeout(id);
  },
});

// make sure that each test actually tests something
// see https://jestjs.io/docs/en/expect#expecthasassertions
beforeEach(() => {
  expect.hasAssertions();
});
