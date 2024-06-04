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
    dismiss();

    expect(document.querySelector(`.js-broadcast-notification-${messageId}`)).toBeNull();
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
