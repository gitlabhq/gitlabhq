
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
    return $(target).tooltip({
      container: 'body',
      html: 'true',
      placement: 'auto bottom',
      title: title,
      trigger: 'manual'
    }).tooltip('show').one('mouseleave', function() {
      return $(this).tooltip('hide');
    });
  };

  $(function() {
    var clipboard;

    clipboard = new Clipboard('[data-clipboard-target], [data-clipboard-text]');
    clipboard.on('success', genericSuccess);
    return clipboard.on('error', genericError);
  });

}).call(this);
