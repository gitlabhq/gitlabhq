import { setAttributes } from '~/lib/utils/dom_utils';
import axios from '~/lib/utils/axios_utils';

const createSandbox = () => {
  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src: '/-/sandbox/swagger',
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
