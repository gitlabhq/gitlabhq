import { renderGFM } from '~/behaviors/markdown/render_gfm';

requestIdleCallback(() => {
  renderGFM(document.querySelector('#content-body .md'));
});
