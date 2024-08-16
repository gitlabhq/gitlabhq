import { oauthCallback } from '@gitlab/web-ide';
import { TEST_HOST } from 'helpers/test_constants';
import { mountOAuthCallback } from '~/ide/mount_oauth_callback';
import { getMockCallbackUrl } from './helpers';

jest.mock('@gitlab/web-ide');

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

  it('calls oauthCallback', () => {
    expect(oauthCallback).not.toHaveBeenCalled();

    mountOAuthCallback();

    expect(oauthCallback).toHaveBeenCalledTimes(1);
    expect(oauthCallback).toHaveBeenCalledWith({
      auth: {
        type: 'oauth',
        callbackUrl: TEST_OAUTH_CALLBACK_URL,
        clientId: TEST_OAUTH_CLIENT_ID,
        protectRefreshToken: true,
      },
      gitlabUrl: `${TEST_HOST}`,
      baseUrl: `${TEST_HOST}/${TEST_GITLAB_WEB_IDE_PUBLIC_PATH}`,
      username: TEST_USERNAME,
    });
  });
});
