import { config as testUtilsConfig } from '@vue/test-utils';
import * as jqueryMatchers from 'custom-jquery-matchers';
import Vue from 'vue';
import 'jquery';
import { setGlobalDateToFakeDate } from 'helpers/fake_date';
import Translate from '~/vue_shared/translate';
import { getJSONFixture, loadHTMLFixture, setHTMLFixture } from './__helpers__/fixtures';
import { initializeTestTimeout } from './__helpers__/timeout';
import customMatchers from './matchers';
import { setupManualMocks } from './mocks/mocks_helper';

import './__helpers__/dom_shims';
import './__helpers__/jquery';
import '~/commons/bootstrap';

// This module has some fairly decent visual test coverage in it's own repository.
jest.mock('@gitlab/favicon-overlay');

process.on('unhandledRejection', global.promiseRejectionHandler);

setupManualMocks();

// Fake the `Date` for the rest of the jest spec runtime environment.
// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39496#note_503084332
setGlobalDateToFakeDate();

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runOnlyPendingTimers();
  }),
);

initializeTestTimeout(process.env.CI ? 6000 : 500);

Vue.config.devtools = false;
Vue.config.productionTip = false;

Vue.use(Translate);

// convenience wrapper for migration from Karma
Object.assign(global, {
  getJSONFixture,
  loadFixtures: loadHTMLFixture,
  setFixtures: setHTMLFixture,
});

// custom-jquery-matchers was written for an old Jest version, we need to make it compatible
Object.entries(jqueryMatchers).forEach(([matcherName, matcherFactory]) => {
  // Don't override existing Jest matcher
  if (matcherName === 'toHaveLength') {
    return;
  }

  expect.extend({
    [matcherName]: matcherFactory().compare,
  });
});

expect.extend(customMatchers);

testUtilsConfig.deprecationWarningHandler = (method, message) => {
  const ALLOWED_DEPRECATED_METHODS = [
    // https://gitlab.com/gitlab-org/gitlab/-/issues/295679
    'finding components with `find` or `get`',

    // https://gitlab.com/gitlab-org/gitlab/-/issues/295680
    'finding components with `findAll`',
  ];
  if (!ALLOWED_DEPRECATED_METHODS.includes(method)) {
    global.console.error(message);
  }
};

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
