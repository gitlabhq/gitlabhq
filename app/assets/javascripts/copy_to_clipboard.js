
/*
//= require clipboard
 */

(function() {
  var genericError, genericSuccess, showTooltip;

  genericSuccess = function(e) {
    showTooltip(e.trigger, 'Copied!');
    e.clearSelection();
    return $(e.trigger).blur();
  };

  genericError = function(e) {
    var key;
    if (/Mac/i.test(navigator.userAgent)) {
      key = '&#8984;';
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
