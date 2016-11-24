/* eslint-disable func-names, space-before-function-paren, one-var, no-var, one-var-declaration-per-line, no-undef, prefer-template, quotes, no-unused-vars, prefer-arrow-callback, padded-blocks, max-len */

/*= require clipboard */

(function() {
  var genericError, genericSuccess, showTooltip;

  genericSuccess = function(e) {
    showTooltip(e.trigger, 'Copied!');
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
      .attr('title', 'Copied!')
      .tooltip('fixTitle')
      .tooltip('show')
      .attr('title', originalTitle)
      .tooltip('fixTitle');
  };

  $(function() {
    var clipboard;

    clipboard = new Clipboard('[data-clipboard-target], [data-clipboard-text]');
    clipboard.on('success', genericSuccess);
    return clipboard.on('error', genericError);
  });

}).call(this);
