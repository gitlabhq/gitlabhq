import $ from 'jquery';
import './autosize';
import initCollapseSidebarOnWindowResize from './collapse_sidebar_on_window_resize';
import initCopyToClipboard from './copy_to_clipboard';
import installGlEmojiElement from './gl_emoji';
import initCopyAsGFM from './markdown/copy_as_gfm';
import { initQuickSubmit } from './quick_submit';
import { initToastMessages } from './toasts';
import { initGlobalAlerts } from './global_alerts';
import './shortcuts';
import './toggler_behavior';
import './preview_markdown';
import './find_and_replace';

installGlEmojiElement();
initCopyAsGFM();
initCopyToClipboard();
initCollapseSidebarOnWindowResize();
initQuickSubmit();
initToastMessages();
initGlobalAlerts();

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
