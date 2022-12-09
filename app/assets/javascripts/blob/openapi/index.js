import { setAttributes } from '~/lib/utils/dom_utils';
import axios from '~/lib/utils/axios_utils';

const createSandbox = () => {
  const iframeEl = document.createElement('iframe');
  setAttributes(iframeEl, {
    src: '/-/sandbox/swagger',
    sandbox: 'allow-scripts allow-popups',
    frameBorder: 0,
    width: '100%',
    // TODO: the height needs to be adjust dynamically,
    // we could add `scrolling: 'no'` after that
    height: '1000',
  });
  return iframeEl;
};

export default async () => {
  const wrapperEl = document.getElementById('js-openapi-viewer');
  const sandboxEl = createSandbox();

  const { data } = await axios.get(wrapperEl.dataset.endpoint);

  wrapperEl.appendChild(sandboxEl);

  sandboxEl.addEventListener('load', () => {
    sandboxEl.contentWindow.postMessage(data, '*');
  });
};
