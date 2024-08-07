import { startIde } from '~/ide/index';
import { IDE_ELEMENT_ID } from '~/ide/constants';
import { OAuthCallbackDomainMismatchErrorApp } from '~/ide/oauth_callback_domain_mismatch_error';
import { initGitlabWebIDE } from '~/ide/init_gitlab_web_ide';

jest.mock('~/ide/init_gitlab_web_ide');

const MOCK_CALLBACK_URL = `${window.location.origin}/ide/redirect`;
const MOCK_DATA_SET = {
  callbackUrls: JSON.stringify([MOCK_CALLBACK_URL]),
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
  afterEach(() => {
    document.getElementById(IDE_ELEMENT_ID).remove();
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
  });

  describe('OAuth callback origin mismatch check', () => {
    let renderErrorSpy;

    beforeEach(() => {
      renderErrorSpy = jest.spyOn(OAuthCallbackDomainMismatchErrorApp.prototype, 'renderError');
    });

    it('does not render error page if no callbackUrl provided', async () => {
      setupMockIdeElement({ useNewWebIde: true });
      await startIde();

      expect(renderErrorSpy).not.toHaveBeenCalled();
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(1);
    });

    it('does not call renderOAuthDomainMismatchError if no mismatch detected', async () => {
      setupMockIdeElement();
      await startIde();

      expect(renderErrorSpy).not.toHaveBeenCalled();
      expect(initGitlabWebIDE).toHaveBeenCalledTimes(1);
    });

    it('renders error page if OAuth callback origin does not match window.location.origin', async () => {
      const MOCK_MISMATCH_CALLBACK_URL = 'https://example.com/ide/redirect';
      renderErrorSpy.mockImplementation(() => {});
      setupMockIdeElement({
        callbackUrls: JSON.stringify([MOCK_MISMATCH_CALLBACK_URL]),
        useNewWebIde: true,
      });

      await startIde();

      expect(renderErrorSpy).toHaveBeenCalledTimes(1);
      expect(initGitlabWebIDE).not.toHaveBeenCalled();
    });
  });
});
