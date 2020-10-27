import $ from 'jquery';
import Clipboard from 'clipboard';
import { sprintf, __ } from '~/locale';
import { fixTitle, show } from '~/tooltips';

function showTooltip(target, title) {
  const { originalTitle } = target.dataset;
  const hideTooltip = () => {
    target.removeEventListener('mouseout', hideTooltip);
    setTimeout(() => {
      target.setAttribute('title', originalTitle);
      fixTitle(target);
    }, 100);
  };

  target.setAttribute('title', title);

  fixTitle(target);
  show(target);

  target.addEventListener('mouseout', hideTooltip);
}

function genericSuccess(e) {
  // Clear the selection and blur the trigger so it loses its border
  e.clearSelection();
  $(e.trigger).blur();

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
  $(document).on('copy', 'body > textarea[readonly]', e => {
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
  const $btnElement = $(btnElement);

  // Ensure the button has already been tooltip'd.
  // If the use hasn't yet interacted (i.e. hovered or clicked)
  // with the button, Bootstrap hasn't yet initialized
  // the tooltip, and its `data-original-title` will be `undefined`.
  // This value is used in the functions above.
  $btnElement.tooltip();
  btnElement.dispatchEvent(new MouseEvent('mouseover'));

  btnElement.click();

  // Manually trigger the necessary events to hide the
  // button's tooltip and allow the button to perform its
  // tooltip cleanup (updating the title from "Copied" back
  // to its original title, "Copy branch name").
  setTimeout(() => {
    btnElement.dispatchEvent(new MouseEvent('mouseout'));
    $btnElement.tooltip('hide');
  }, 2000);
}
