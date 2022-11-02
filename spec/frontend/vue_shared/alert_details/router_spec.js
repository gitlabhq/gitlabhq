import createRouter from '~/vue_shared/alert_details/router';
import setWindowLocation from 'helpers/set_window_location_helper';

const BASE_PATH = '/-/alert_management/1/details';
const EMPTY_HASH = '';
const NOOP = () => {};

describe('AlertDetails router', () => {
  const originalLocation = window.location.href;
  let router;

  beforeEach(() => {
    setWindowLocation(originalLocation);
    router = createRouter(BASE_PATH);
  });

  describe('redirects hash route mode URLs to history route mode', () => {
    it.each`
      hashPath         | historyPath
      ${'/#/overview'} | ${'/overview'}
      ${'#/overview'}  | ${'/overview'}
      ${'/#/'}         | ${'/'}
      ${'#/'}          | ${'/'}
      ${'/#'}          | ${'/'}
      ${'#'}           | ${'/'}
      ${'/'}           | ${'/'}
      ${'/overview'}   | ${'/overview'}
    `('should redirect "$hashPath" to "$historyPath"', ({ hashPath, historyPath }) => {
      router.push(hashPath, NOOP);

      expect(window.location.hash).toBe(EMPTY_HASH);
      expect(window.location.pathname).toBe(BASE_PATH + historyPath);
    });
  });
});
