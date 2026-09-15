import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { ignoreConsoleMessages } from 'helpers/console_watcher';
import { initVueActivityCalendar } from '~/pages/users/vue_activity_calendar';
import AjaxCache from '~/lib/utils/ajax_cache';

jest.mock('~/lib/utils/ajax_cache');

describe('initVueActivityCalendar', () => {
  const username = 'root';
  const utcOffset = '-18000';
  const errorTitle = "There was an error loading the user's activity calendar.";

  const mountApp = (dataset = `data-username="${username}" data-utc-offset="${utcOffset}"`) => {
    setHTMLFixture(`<div id="js-vue-activity-calendar" ${dataset}></div>`);

    return initVueActivityCalendar();
  };

  const findAlertTitle = () => document.querySelector('.gl-alert-title')?.textContent.trim();

  beforeEach(() => {
    AjaxCache.retrieve.mockResolvedValue({});
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('returns null when the mount element is missing', () => {
    setHTMLFixture('<div></div>');

    expect(initVueActivityCalendar()).toBeNull();
  });

  it('provides `username`, so the calendar request targets that user', async () => {
    mountApp();
    await waitForPromises();

    expect(AjaxCache.retrieve).toHaveBeenCalledWith(`/users/${username}/calendar.json`);
    expect(findAlertTitle()).toBeUndefined();
  });

  // ActivityCalendar injects `username` to build the calendar path. Nothing statically
  // links this provide to that inject, so this documents what breaks without it.
  describe('when `username` is not provided', () => {
    ignoreConsoleMessages([/^\[Vue warn\]: Injection "username" not found/]);

    it('never requests the calendar and renders the error alert', async () => {
      mountApp(`data-utc-offset="${utcOffset}"`);
      await waitForPromises();

      expect(AjaxCache.retrieve).not.toHaveBeenCalled();
      expect(findAlertTitle()).toBe(errorTitle);
    });
  });
});
