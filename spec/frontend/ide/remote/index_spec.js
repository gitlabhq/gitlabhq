import { startRemote } from '@gitlab/web-ide';
import { getBaseConfig, setupRootElement } from '~/ide/lib/gitlab_web_ide';
import { mountRemoteIDE } from '~/ide/remote';
import { TEST_HOST } from 'helpers/test_constants';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { handleTracking } from '~/ide/lib/gitlab_web_ide/handle_tracking_event';

jest.mock('@gitlab/web-ide');
jest.mock('~/ide/lib/gitlab_web_ide');

const TEST_DATA = {
  remoteHost: 'example.com:3443',
  remotePath: 'test/path/gitlab',
  cspNonce: 'just7some8noncense',
  connectionToken: 'connectAtoken',
  returnUrl: 'https://example.com/return',
};

const TEST_BASE_CONFIG = {
  gitlabUrl: '/test/gitlab',
};

const TEST_RETURN_URL_SAME_ORIGIN = `${TEST_HOST}/foo/example`;

describe('~/ide/remote/index', () => {
  useMockLocationHelper();
  const originalHref = window.location.href;
  let el;
  let rootEl;

  beforeEach(() => {
    el = document.createElement('div');
    Object.entries(TEST_DATA).forEach(([key, value]) => {
      el.dataset[key] = value;
    });

    // Stub setupRootElement so we can assert on return element
    rootEl = document.createElement('div');
    setupRootElement.mockReturnValue(rootEl);

    // Stub getBaseConfig so we can assert
    getBaseConfig.mockReturnValue(TEST_BASE_CONFIG);
  });

  describe('default', () => {
    beforeEach(() => {
      mountRemoteIDE(el);
    });

    it('calls startRemote', () => {
      expect(startRemote).toHaveBeenCalledWith(rootEl, {
        ...TEST_BASE_CONFIG,
        nonce: TEST_DATA.cspNonce,
        connectionToken: TEST_DATA.connectionToken,
        remoteAuthority: `/${TEST_DATA.remoteHost}`,
        hostPath: `/${TEST_DATA.remotePath}`,
        handleError: expect.any(Function),
        handleClose: expect.any(Function),
        handleTracking,
      });
    });
  });

  describe.each`
    returnUrl                      | fnName           | reloadExpectation | hrefExpectation
    ${TEST_DATA.returnUrl}         | ${'handleError'} | ${1}              | ${originalHref}
    ${TEST_DATA.returnUrl}         | ${'handleClose'} | ${1}              | ${originalHref}
    ${TEST_RETURN_URL_SAME_ORIGIN} | ${'handleClose'} | ${0}              | ${TEST_RETURN_URL_SAME_ORIGIN}
    ${TEST_RETURN_URL_SAME_ORIGIN} | ${'handleError'} | ${0}              | ${TEST_RETURN_URL_SAME_ORIGIN}
    ${''}                          | ${'handleClose'} | ${1}              | ${originalHref}
  `(
    'with returnUrl=$returnUrl and fn=$fnName',
    ({ returnUrl, fnName, reloadExpectation, hrefExpectation }) => {
      beforeEach(() => {
        el.dataset.returnUrl = returnUrl;

        mountRemoteIDE(el);
      });

      it('changes location', () => {
        expect(window.location.reload).not.toHaveBeenCalled();

        const [, config] = startRemote.mock.calls[0];

        config[fnName]();

        expect(window.location.reload).toHaveBeenCalledTimes(reloadExpectation);
        expect(window.location.href).toBe(hrefExpectation);
      });
    },
  );
});
