import MockAdapter from 'axios-mock-adapter';
import Cookies from '~/lib/utils/cookies';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initBroadcastNotifications from '~/broadcast_notification';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

describe('broadcast message on dismiss', () => {
  const dismiss = () => {
    const button = document.querySelector('.js-dismiss-current-broadcast-notification');
    button.click();
  };
  const endsAt = '2020-01-01T00:00:00Z';
  const dismissalPath = '/-/users/broadcast_message_dismissals';
  const messageId = '1';
  const cookieKey = `hide_broadcast_message_${messageId}`;
  /** @type { MockAdapter } */
  let mockAxios;

  beforeEach(() => {
    setHTMLFixture(`
    <div class="js-broadcast-notification-${messageId}">
      <button
        class="js-dismiss-current-broadcast-notification"
        data-id="${messageId}"
        data-expire-date="${endsAt}"
        data-dismissal-path="${dismissalPath}"
        data-cookie-key="${cookieKey}"
      ></button>
    </div>
    `);

    mockAxios = new MockAdapter(axios);

    initBroadcastNotifications();
  });

  afterEach(() => {
    resetHTMLFixture();
    mockAxios.restore();
  });

  it('removes broadcast message', () => {
    document.documentElement.style.removeProperty('--broadcast-message-height');
    dismiss();

    expect(document.querySelector(`.js-broadcast-notification-${messageId}`)).toBeNull();
    expect(document.documentElement.style.getPropertyValue('--broadcast-message-height')).toBe(
      '0px',
    );
  });

  it('calls Cookies.set', () => {
    jest.spyOn(Cookies, 'set');
    dismiss();

    expect(Cookies.set).toHaveBeenCalledWith(cookieKey, true, {
      expires: new Date(endsAt),
      secure: false,
    });
  });

  describe('when data-dismissal-path is set', () => {
    it('calls broadcast_message_dismissal endpoint with message id', async () => {
      jest.spyOn(axios, 'post');

      dismiss();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledTimes(1);
      expect(axios.post).toHaveBeenCalledWith(dismissalPath, {
        broadcast_message_id: messageId,
        expires_at: endsAt,
      });
    });
  });

  describe('when data-dismissal-path is not set', () => {
    beforeEach(() => {
      const button = document.querySelector('button');
      delete button.dataset.dismissalPath;
    });

    it('does not call broadcast_message_dismissal endpoint', async () => {
      jest.spyOn(axios, 'post');

      dismiss();
      await waitForPromises();

      expect(axios.post).toHaveBeenCalledTimes(0);
    });
  });

  it('captures error using Sentry', async () => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();

    mockAxios
      .onPost(dismissalPath, {
        broadcast_message_id: messageId,
        expires_at: endsAt,
      })
      .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

    dismiss();
    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
  });
});

describe('setBroadcastMessageHeightOffset', () => {
  beforeEach(() => {
    setHTMLFixture(`
        <div data-broadcast-banner class="gl-broadcast-message">
          Here is a broadcast message
        </div>
        <div data-broadcast-banner class="gl-broadcast-message">
          Here is another broadcast message
        </div>
      `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('sets the height offset for the broadcast message', () => {
    window.HTMLDivElement.prototype.getBoundingClientRect = () => ({ height: 50 });
    jest.spyOn(document.documentElement.style, 'setProperty');
    jest.spyOn(window.HTMLDivElement.prototype, 'getBoundingClientRect');

    initBroadcastNotifications();

    expect(window.HTMLDivElement.prototype.getBoundingClientRect).toHaveBeenCalledTimes(2);

    expect(document.documentElement.style.setProperty).toHaveBeenCalledWith(
      '--broadcast-message-height',
      '100px',
    );

    const cssVariableValue = document.documentElement.style.getPropertyValue(
      '--broadcast-message-height',
    );

    expect(cssVariableValue).toBe('100px');
  });
});
