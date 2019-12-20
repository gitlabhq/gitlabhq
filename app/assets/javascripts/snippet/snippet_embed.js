import { __ } from '~/locale';
import { parseUrlPathname, parseUrl } from '../lib/utils/common_utils';

function swapActiveState(activateBtn, deactivateBtn) {
  activateBtn.classList.add('is-active');
  deactivateBtn.classList.remove('is-active');
}

export default () => {
  const shareBtn = document.querySelector('.js-share-btn');

  if (shareBtn) {
    const embedBtn = document.querySelector('.js-embed-btn');
    const snippetUrlArea = document.querySelector('.js-snippet-url-area');
    const embedAction = document.querySelector('.js-embed-action');
    const dataUrl = snippetUrlArea.getAttribute('data-url');

    snippetUrlArea.addEventListener('click', () => snippetUrlArea.select());

    shareBtn.addEventListener('click', () => {
      swapActiveState(shareBtn, embedBtn);
      snippetUrlArea.value = dataUrl;
      embedAction.innerText = __('Share');
    });

    embedBtn.addEventListener('click', () => {
      const parser = parseUrl(dataUrl);
      const url = `${parser.origin + parseUrlPathname(dataUrl)}`;
      const params = parser.search;
      const scriptTag = `<script src="${url}.js${params}"></script>`;

      swapActiveState(embedBtn, shareBtn);
      snippetUrlArea.value = scriptTag;
      embedAction.innerText = __('Embed');
    });
  }
};
