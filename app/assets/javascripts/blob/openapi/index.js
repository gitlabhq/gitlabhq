import { setAttributes } from '~/lib/utils/dom_utils';
import axios from '~/lib/utils/axios_utils';
import {
  getBaseURL,
  relativePathToAbsolute,
  joinPaths,
  setUrlParams,
} from '~/lib/utils/url_utility';

const SANDBOX_FRAME_PATH = '/-/sandbox/swagger';

const getSandboxFrameSrc = () => {
  const path = joinPaths(gon.relative_url_root || '', SANDBOX_FRAME_PATH);
  const absoluteUrl = relativePathToAbsolute(path, getBaseURL());
  if (window.gon?.relative_url_root) {
    return setUrlParams({ relativeRootPath: window.gon.relative_url_root }, absoluteUrl);
  }
  return absoluteUrl;
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

  const { data } = await axios.get(wrapperEl.dataset.endpoint);

  wrapperEl.appendChild(sandboxEl);

  sandboxEl.addEventListener('load', () => {
    sandboxEl.contentWindow.postMessage(data, '*');
  });
};
