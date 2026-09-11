import { oauthCallback } from '@gitlab/web-ide';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/alert';
import { mountOAuthCallback } from '~/ide/mount_oauth_callback';
import { getMockCallbackUrl } from './helpers';

jest.mock('@gitlab/web-ide');
jest.mock('~/alert');

const TEST_USERNAME = 'gandalf.the.grey';
const TEST_GITLAB_WEB_IDE_PUBLIC_PATH = 'test/webpack/assets/gitlab-web-ide/public/path';

const TEST_OAUTH_CLIENT_ID = 'oauth-client-id-123abc';
const TEST_OAUTH_CALLBACK_URL = getMockCallbackUrl();

describe('~/ide/mount_oauth_callback', () => {
  const createRootElement = () => {
    const el = document.createElement('div');

    el.id = 'ide';
    el.dataset.clientId = TEST_OAUTH_CLIENT_ID;
    el.dataset.callbackUrls = [TEST_OAUTH_CALLBACK_URL];

    document.body.append(el);
  };

  beforeEach(() => {
    gon.current_username = TEST_USERNAME;
    process.env.GITLAB_WEB_IDE_PUBLIC_PATH = TEST_GITLAB_WEB_IDE_PUBLIC_PATH;

    createRootElement();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('calls oauthCallback', async () => {
    expect(oauthCallback).not.toHaveBeenCalled();

    await mountOAuthCallback();

    expect(oauthCallback).toHaveBeenCalledTimes(1);
    expect(oauthCallback).toHaveBeenCalledWith({
      auth: {
        type: 'oauth',
        callbackUrl: TEST_OAUTH_CALLBACK_URL,
        clientId: TEST_OAUTH_CLIENT_ID,
        protectRefreshToken: true,
      },
      gitlabUrl: `${TEST_HOST}`,
      username: TEST_USERNAME,
      embedderOriginUrl: TEST_HOST,
    });
  });

  describe('when oauthCallback fails', () => {
    const mockError = new Error('oauthCallback failed');

    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation();
      oauthCallback.mockRejectedValueOnce(mockError);
    });

    it('displays an alert when oauthCallback fails', async () => {
      expect(createAlert).not.toHaveBeenCalled();

      await mountOAuthCallback();

      expect(oauthCallback).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'Unable to authorize GitLab Web IDE access. For more information, see the developer console.',
        containerSelector: '.alert-wrapper',
        dismissible: false,
        primaryButton: {
          clickHandler: expect.any(Function),
          text: 'Close tab',
        },
      });
    });

    it('logs the error in the console', async () => {
      await mountOAuthCallback();
      // eslint-disable-next-line no-console
      expect(console.error).toHaveBeenCalledTimes(1);
      // eslint-disable-next-line no-console
      expect(console.error).toHaveBeenCalledWith(mockError);
    });
  });
});
