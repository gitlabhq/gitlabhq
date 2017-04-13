/* eslint-disable func-names, space-before-function-paren, one-var, no-var, one-var-declaration-per-line, prefer-template, quotes, no-unused-vars, prefer-arrow-callback, max-len */

import Clipboard from 'vendor/clipboard';

var genericError, genericSuccess, showTooltip;

genericSuccess = function(e) {
  showTooltip(e.trigger, 'Copied');
  // Clear the selection and blur the trigger so it loses its border
  e.clearSelection();
  return $(e.trigger).blur();
};

// Safari doesn't support `execCommand`, so instead we inform the user to
// copy manually.
//
// See http://clipboardjs.com/#browser-support
genericError = function(e) {
  var key;
  if (/Mac/i.test(navigator.userAgent)) {
    key = '&#8984;'; // Command
  } else {
    key = 'Ctrl';
  }
  return showTooltip(e.trigger, "Press " + key + "-C to copy");
};

showTooltip = function(target, title) {
  var $target = $(target);
  var originalTitle = $target.data('original-title');

  $target
    .attr('title', 'Copied')
    .tooltip('fixTitle')
    .tooltip('show')
    .attr('title', originalTitle)
    .tooltip('fixTitle');
};

$(function() {
  const clipboard = new Clipboard('[data-clipboard-target], [data-clipboard-text]');
  clipboard.on('success', genericSuccess);
  clipboard.on('error', genericError);

  // This a workaround around ClipboardJS limitations to allow the context-specific copy/pasting of plain text or GFM.
  // The Ruby `clipboard_button` helper sneaks a JSON hash with `text` and `gfm` keys into the `data-clipboard-text`
  // attribute that ClipboardJS reads from.
  // When ClipboardJS creates a new `textarea` (directly inside `body`, with a `readonly` attribute`), sets its value
  // to the value of this data attribute, focusses on it, and finally programmatically issues the 'Copy' command,
  // this code intercepts the copy command/event at the last minute to deconstruct this JSON hash and set the
  // `text/plain` and `text/x-gfm` copy data types to the intended values.
  $(document).on('copy', 'body > textarea[readonly]', function(e) {
    const clipboardData = e.originalEvent.clipboardData;
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
});
