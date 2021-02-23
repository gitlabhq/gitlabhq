import Clipboard from 'clipboard';
import $ from 'jquery';
import { sprintf, __ } from '~/locale';
import { fixTitle, add, show, once } from '~/tooltips';

function showTooltip(target, title) {
  const { title: originalTitle } = target.dataset;

  once('hidden', (tooltip) => {
    if (tooltip.target === target) {
      target.setAttribute('title', originalTitle);
      fixTitle(target);
    }
  });

  target.setAttribute('title', title);
  fixTitle(target);
  show(target);
  setTimeout(() => target.blur(), 1000);
}

function genericSuccess(e) {
  // Clear the selection and blur the trigger so it loses its border
  e.clearSelection();
  showTooltip(e.trigger, __('Copied'));
}

/**
 * Safari > 10 doesn't support `execCommand`, so instead we inform the user to copy manually.
 * See http://clipboardjs.com/#browser-support
 */
function genericError(e) {
  let key;
  if (/Mac/i.test(navigator.userAgent)) {
    key = '&#8984;'; // Command
  } else {
    key = 'Ctrl';
  }
  showTooltip(e.trigger, sprintf(__(`Press %{key}-C to copy`), { key }));
}

export default function initCopyToClipboard() {
  const clipboard = new Clipboard('[data-clipboard-target], [data-clipboard-text]');
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
}

/**
 * Programmatically triggers a click event on a
 * "copy to clipboard" button, causing its
 * contents to be copied. Handles some of the messiniess
 * around managing the button's tooltip.
 * @param {HTMLElement} btnElement
 */
export function clickCopyToClipboardButton(btnElement) {
  // Ensure the button has already been tooltip'd.
  add([btnElement], { show: true });

  btnElement.click();
}
