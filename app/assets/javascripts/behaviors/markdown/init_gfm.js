import $ from 'jquery';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

$.fn.renderGFM = function plugin() {
  this.get().forEach(renderGFM);
  return this;
};
requestIdleCallback(
  () => {
    renderGFM(document.body);
  },
  { timeout: 500 },
);
