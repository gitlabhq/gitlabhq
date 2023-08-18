/* Common setup for both unit and integration test environments */
import { ReadableStream, WritableStream } from 'node:stream/web';
import * as jqueryMatchers from 'custom-jquery-matchers';
import Vue from 'vue';
import { enableAutoDestroy } from '@vue/test-utils';
import 'jquery';
import Translate from '~/vue_shared/translate';
import setWindowLocation from './set_window_location_helper';
import { createGon } from './gon_helper';
import { setGlobalDateToFakeDate } from './fake_date';
import { TEST_HOST } from './test_constants';
import * as customMatchers from './matchers';

import './dom_shims';
import './jquery';
import '~/commons/bootstrap';

global.ReadableStream = ReadableStream;
global.WritableStream = WritableStream;

enableAutoDestroy(afterEach);

// This module has some fairly decent visual test coverage in it's own repository.
jest.mock('@gitlab/favicon-overlay');
jest.mock('~/lib/utils/axios_utils', () => jest.requireActual('helpers/mocks/axios_utils'));

process.on('unhandledRejection', global.promiseRejectionHandler);

// Fake the `Date` for the rest of the jest spec runtime environment.
// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39496#note_503084332
setGlobalDateToFakeDate();

Vue.config.devtools = false;
Vue.config.productionTip = false;

Vue.use(Translate);

const JQUERY_MATCHERS_TO_EXCLUDE = ['toBeEmpty', 'toHaveLength', 'toExist'];

// custom-jquery-matchers was written for an old Jest version, we need to make it compatible
Object.entries(jqueryMatchers).forEach(([matcherName, matcherFactory]) => {
  // Exclude these jQuery matchers
  if (JQUERY_MATCHERS_TO_EXCLUDE.includes(matcherName)) {
    return;
  }

  expect.extend({
    [matcherName]: matcherFactory().compare,
  });
});

expect.extend(customMatchers);

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

beforeEach(() => {
  // make sure that each test actually tests something
  // see https://jestjs.io/docs/en/expect#expecthasassertions
  // eslint-disable-next-line jest/no-standalone-expect
  expect.hasAssertions();

  // Reset globals: This ensures tests don't interfere with
  // each other, and removes the need to tidy up if it was
  // changed for a given test.

  // Reset the mocked window.location
  setWindowLocation(TEST_HOST);

  // Reset window.gon object
  window.gon = createGon(window.IS_EE);
});
