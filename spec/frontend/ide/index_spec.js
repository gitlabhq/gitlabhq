import { startIde } from '~/ide/index';
import { IDE_ELEMENT_ID } from '~/ide/constants';
import { OAuthCallbackDomainMismatchErrorApp } from '~/ide/oauth_callback_domain_mismatch_error';
import { initGitlabWebIDE } from '~/ide/init_gitlab_web_ide';
import { initLegacyWebIDE } from '~/ide/init_legacy_web_ide';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/ide/init_gitlab_web_ide');
jest.mock('~/ide/init_legacy_web_ide');

const MOCK_MISMATCH_CALLBACK_URL = 'https://example.com/ide/redirect';

const MOCK_DATA_SET = {
  callbackUrls: JSON.stringify([`${TEST_HOST}/-/ide/oauth_redirect`]),
  useNewWebIde: true,
};
/**
 *
 * @param {Object} mockDataSet - data set key to value pair to add to mock IDE element
 */
const setupMockIdeElement = (customData = MOCK_DATA_SET) => {
  const el = document.createElement('div');
  el.id = IDE_ELEMENT_ID;

  for (const [key, value] of Object.entries(customData)) {
    el.dataset[key] = value;
  }
  document.body.append(el);

  return el;
};

describe('startIde', () => {
  let renderErrorSpy;

  beforeEach(() => {
    setWindowLocation(`${TEST_HOST}/-/ide/edit/gitlab-org/gitlab`);
    renderErrorSpy = jest.spyOn(OAuthCallbackDomainMismatchErrorApp.prototype, 'renderError');
  });

  afterEach(() => {
    document.getElementById(IDE_ELEMENT_ID)?.remove();
  });

  describe('when useNewWebIde feature flag is true', () => {
    let ideElement;

    beforeEach(async () => {
      ideElement = setupMockIdeElement();

      await startIde();
    });

    it('calls initGitlabWebIDE', () => {
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(1);
      expect(initGitlabWebIDE).toHaveBeenCalledWith(ideElement);
    });

    it('does not render error page', () => {
      expect(renderErrorSpy).not.toHaveBeenCalled();
    });
  });

  describe('with mismatch callback url', () => {
    it('renders error page', async () => {
      setupMockIdeElement({
        callbackUrls: JSON.stringify([MOCK_MISMATCH_CALLBACK_URL]),
        useNewWebIde: true,
      });

      await startIde();

      expect(renderErrorSpy).toHaveBeenCalledTimes(1);
      expect(initGitlabWebIDE).not.toHaveBeenCalled();
    });
  });

  describe('when there is a case mismatch in the domain name of the callback URL', () => {
    it('renders error page', async () => {
      const parsedUrl = new URL(TEST_HOST);

      setupMockIdeElement({
        callbackUrls: JSON.stringify([
          `${parsedUrl.protocol}//${parsedUrl.host.toUpperCase()}/-/ide/oauth_redirect`,
        ]),
        useNewWebIde: true,
      });

      await startIde();

      expect(renderErrorSpy).not.toHaveBeenCalled();
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(1);
    });
  });

  describe('when the callback URL is invalid', () => {
    it('renders error page', async () => {
      setupMockIdeElement({
        callbackUrls: JSON.stringify(['/-/ide/oauth_redirect']),
        useNewWebIde: true,
      });

      await startIde();

      expect(renderErrorSpy).not.toHaveBeenCalled();
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(1);
    });
  });

  describe('with relative URL location and mismatch callback url', () => {
    it('renders error page', async () => {
      setWindowLocation(`${TEST_HOST}/relative-path/-/ide/edit/project`);

      setupMockIdeElement();

      await startIde();

      expect(renderErrorSpy).toHaveBeenCalledTimes(1);
      expect(initGitlabWebIDE).not.toHaveBeenCalled();
    });
  });

  describe('when useNewWebIde feature flag is false', () => {
    beforeEach(async () => {
      setupMockIdeElement({ useNewWebIde: false });

      await startIde();
    });

    it('calls initGitlabWebIDE', () => {
      expect(initLegacyWebIDE).toHaveBeenCalledTimes(1);
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(0);
    });

    it('does not render error page', () => {
      expect(renderErrorSpy).not.toHaveBeenCalled();
    });
  });
});
