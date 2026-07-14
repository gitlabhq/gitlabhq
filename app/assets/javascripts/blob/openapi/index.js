import SwaggerClient from 'swagger-client';
import { setAttributes } from '~/lib/utils/dom_utils';
import {
  getBaseURL,
  relativePathToAbsolute,
  setUrlParams,
  getParameterByName,
} from '~/lib/utils/url_utility';
import { sandboxSwaggerPath } from '~/lib/utils/path_helpers/routes';

const getSandboxFrameSrc = () => {
  const absoluteUrl = relativePathToAbsolute(sandboxSwaggerPath(), getBaseURL());
  const displayOperationId = getParameterByName('displayOperationId');
  const params = { displayOperationId };
  return setUrlParams(params, { url: absoluteUrl });
};

const createSandbox = () => {
  const iframeEl = document.createElement('iframe');

  setAttributes(iframeEl, {
    src: getSandboxFrameSrc(),
    sandbox: 'allow-scripts allow-popups allow-forms',
    frameBorder: 0,
    width: '100%',
    // The height will be adjusted dynamically.
    // Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/377969
    height: '1000',
  });
  return iframeEl;
};

export default async (el = document.getElementById('js-openapi-viewer')) => {
  const wrapperEl = el;
  const sandboxEl = createSandbox();

  const { spec } = await SwaggerClient.resolve({ url: wrapperEl.dataset.endpoint });

  wrapperEl.appendChild(sandboxEl);

  sandboxEl.addEventListener('load', () => {
    // pass information via postMessage instead of query parameter to prevent the user from modifying query parameter
    const message = {
      type: 'swagger-init',
      spec,
      // eslint-disable-next-line @gitlab/no-hardcoded-urls -- Needed to render swagger UI in app/assets/javascripts/lib/swagger.js
      relativeRootPath: window.gon?.relative_url_root || null,
    };

    if (spec) sandboxEl.contentWindow.postMessage(JSON.stringify(message), '*');
  });
};
