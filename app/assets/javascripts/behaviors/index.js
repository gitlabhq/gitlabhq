import $ from 'jquery';
import './autosize';
import initCollapseSidebarOnWindowResize from './collapse_sidebar_on_window_resize';
import initCopyToClipboard from './copy_to_clipboard';
import installGlEmojiElement from './gl_emoji';
import { loadStartupCSS } from './load_startup_css';
import initCopyAsGFM from './markdown/copy_as_gfm';
import './quick_submit';
import './requires_input';
import initPageShortcuts from './shortcuts';
import './toggler_behavior';
import './preview_markdown';

loadStartupCSS();

installGlEmojiElement();

initCopyAsGFM();
initCopyToClipboard();

initPageShortcuts();
initCollapseSidebarOnWindowResize();

window.requestIdleCallback(
  () => {
    // Check if we have to Load GFM Input
    const $gfmInputs = $('.js-gfm-input:not(.js-gfm-input-initialized)');
    if ($gfmInputs.length) {
      import(/* webpackChunkName: 'initGFMInput' */ './markdown/gfm_auto_complete')
        .then(({ default: initGFMInput }) => {
          initGFMInput($gfmInputs);
        })
        .catch(() => {});
    }
  },
  { timeout: 500 },
);
