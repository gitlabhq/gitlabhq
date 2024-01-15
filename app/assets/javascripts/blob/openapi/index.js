import SwaggerClient from 'swagger-client';
import { setAttributes } from '~/lib/utils/dom_utils';
import {
  getBaseURL,
  relativePathToAbsolute,
  joinPaths,
  setUrlParams,
  getParameterByName,
} from '~/lib/utils/url_utility';

const SANDBOX_FRAME_PATH = '/-/sandbox/swagger';

const getSandboxFrameSrc = () => {
  const path = joinPaths(gon.relative_url_root || '', SANDBOX_FRAME_PATH);
  const absoluteUrl = relativePathToAbsolute(path, getBaseURL());
  const displayOperationId = getParameterByName('displayOperationId');
  const params = { displayOperationId };

  if (window.gon?.relative_url_root) {
    params.relativeRootPath = window.gon.relative_url_root;
  }

  return setUrlParams(params, absoluteUrl);
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
    if (spec) sandboxEl.contentWindow.postMessage(JSON.stringify(spec), '*');
  });
};
