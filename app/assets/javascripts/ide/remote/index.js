import { startRemote } from '@gitlab/web-ide';
import { getBaseConfig, setupRootElement } from '~/ide/lib/gitlab_web_ide';
import { isSameOriginUrl, joinPaths } from '~/lib/utils/url_utility';
import { handleTracking } from '~/ide/lib/gitlab_web_ide/handle_tracking_event';

/**
 * @param {Element} rootEl
 */
export const mountRemoteIDE = async (el) => {
  const {
    remoteHost: remoteAuthority,
    remotePath: hostPath,
    cspNonce,
    connectionToken,
    returnUrl,
  } = el.dataset;

  const rootEl = setupRootElement(el);

  const visitReturnUrl = () => {
    // security: Only change `href` if of the same origin as current page
    if (returnUrl && isSameOriginUrl(returnUrl)) {
      window.location.href = returnUrl;
    } else {
      window.location.reload();
    }
  };

  startRemote(rootEl, {
    ...getBaseConfig(),
    nonce: cspNonce,
    connectionToken,
    // remoteAuthority must start with "/"
    remoteAuthority: joinPaths('/', remoteAuthority),
    // hostPath must start with "/"
    hostPath: joinPaths('/', hostPath),
    // TODO Handle error better
    handleError: visitReturnUrl,
    handleClose: visitReturnUrl,
    handleTracking,
  });
};
