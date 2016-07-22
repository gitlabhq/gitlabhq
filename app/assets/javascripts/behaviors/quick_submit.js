
/*= require extensions/jquery */
var isMac, keyCodeIs;

isMac = function() {
  return navigator.userAgent.match(/Macintosh/);
};

keyCodeIs = function(e, keyCode) {
  if ((e.originalEvent && e.originalEvent.repeat) || e.repeat) {
    return false;
  }
  return e.keyCode === keyCode;
};

$(document).on('keydown.quick_submit', '.js-quick-submit', function(e) {
  var $form, $submit_button;
  if (!keyCodeIs(e, 13)) {
    return;
  }
  if (!((e.metaKey && !e.altKey && !e.ctrlKey && !e.shiftKey) || (e.ctrlKey && !e.altKey && !e.metaKey && !e.shiftKey))) {
    return;
  }
  e.preventDefault();
  $form = $(e.target).closest('form');
  $submit_button = $form.find('input[type=submit], button[type=submit]');
  if ($submit_button.attr('disabled')) {
    return;
  }
  $submit_button.disable();
  return $form.submit();
});

$(document).on('keyup.quick_submit', '.js-quick-submit input[type=submit], .js-quick-submit button[type=submit]', function(e) {
  var $this, title;
  if (!keyCodeIs(e, 9)) {
    return;
  }
  if (isMac()) {
    title = "You can also press &#8984;-Enter";
  } else {
    title = "You can also press Ctrl-Enter";
  }
  $this = $(this);
  return $this.tooltip({
    container: 'body',
    html: 'true',
    placement: 'auto top',
    title: title,
    trigger: 'manual'
  }).tooltip('show').one('blur', function() {
    return $this.tooltip('hide');
  });
});
