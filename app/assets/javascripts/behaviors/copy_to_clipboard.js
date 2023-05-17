import ClipboardJS from 'clipboard';
import $ from 'jquery';

import { parseBoolean } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { fixTitle, add, show, hide, once } from '~/tooltips';

const CLIPBOARD_SUCCESS_EVENT = 'clipboard-success';
const CLIPBOARD_ERROR_EVENT = 'clipboard-error';
const I18N_ERROR_MESSAGE = __('Copy failed. Please manually copy the value.');

function showTooltip(target, title) {
  const { originalTitle } = target.dataset;

  once('hidden', (tooltip) => {
    if (originalTitle && tooltip.target === target) {
      target.setAttribute('title', originalTitle);
      target.setAttribute('aria-label', originalTitle);
      fixTitle(target);
    }
  });

  target.setAttribute('title', title);
  target.setAttribute('aria-label', title);
  fixTitle(target);
  show(target);
  setTimeout(() => {
    hide(target);
  }, 1000);
}

function genericSuccess(e) {
  // Clear the selection
  e.clearSelection();
  e.trigger.focus();
  e.trigger.dispatchEvent(new Event(CLIPBOARD_SUCCESS_EVENT));

  const { clipboardHandleTooltip = true } = e.trigger.dataset;
  if (parseBoolean(clipboardHandleTooltip)) {
    // Update tooltip
    showTooltip(e.trigger, __('Copied'));
  }
}

/**
 * Safari < 10 doesn't support `execCommand`, so instead we inform the user to copy manually.
 * See http://clipboardjs.com/#browser-support
 */
function genericError(e) {
  e.trigger.dispatchEvent(new Event(CLIPBOARD_ERROR_EVENT));

  const { clipboardHandleTooltip = true } = e.trigger.dataset;
  if (parseBoolean(clipboardHandleTooltip)) {
    showTooltip(e.trigger, I18N_ERROR_MESSAGE);
  }
}

export default function initCopyToClipboard() {
  const clipboard = new ClipboardJS('[data-clipboard-target], [data-clipboard-text]');
  clipboard.on('success', genericSuccess);
  clipboard.on('error', genericError);

  /**
   * This a workaround around ClipboardJS limitations to allow the context-specific copy/pasting
   * of plain text or GFM. The Ruby `clipboard_button` helper sneaks a JSON hash with `text` and
   * `gfm` keys into the `data-clipboard-text` attribute that ClipboardJS reads from.
   * When ClipboardJS creates a new `textarea` (directly inside `body`, with a `readonly`
   * attribute`), sets its value to the value of this data attribute, focusses on it, and finally
   * programmatically issues the 'Copy' command, this code intercepts the copy command/event at
   * the last minute to deconstruct this JSON hash and set the `text/plain` and `text/x-gfm` copy
   * data types to the intended values.
   */
  $(document).on('copy', 'body > textarea[readonly]', (e) => {
    const { clipboardData } = e.originalEvent;
    if (!clipboardData) return;

    const text = e.target.value;

    let json;
    try {
      json = JSON.parse(text);
    } catch (ex) {
      return;
    }

    if (!json.text || !json.gfm) return;

    e.preventDefault();

    clipboardData.setData('text/plain', json.text);
    clipboardData.setData('text/x-gfm', json.gfm);
  });

  return clipboard;
}

/**
 * Programmatically triggers a click event on a
 * "copy to clipboard" button, causing its
 * contents to be copied. Handles some of the messiniess
 * around managing the button's tooltip.
 * @param {HTMLElement} btnElement
 */
export function clickCopyToClipboardButton(btnElement) {
  const { clipboardHandleTooltip = true } = btnElement.dataset;

  if (parseBoolean(clipboardHandleTooltip)) {
    // Ensure the button has already been tooltip'd.
    add([btnElement], { show: true });
  }

  btnElement.click();
}

export { CLIPBOARD_SUCCESS_EVENT, CLIPBOARD_ERROR_EVENT, I18N_ERROR_MESSAGE };
