import $ from 'jquery';
import '../commons/bootstrap';
import { isInIssuePage } from '../lib/utils/common_utils';

// Quick Submit behavior
//
// When a child field of a form with a `js-quick-submit` class receives a
// "Meta+Enter" (Mac) or "Ctrl+Enter" (Linux/Windows) key combination, the form
// is submitted.
//
// ### Example Markup
//
//   <form action="/foo" class="js-quick-submit">
//     <input type="text" />
//     <textarea></textarea>
//     <input type="submit" value="Submit" />
//   </form>
//

function isMac() {
  return navigator.userAgent.match(/Macintosh/);
}

function keyCodeIs(e, keyCode) {
  if ((e.originalEvent && e.originalEvent.repeat) || e.repeat) {
    return false;
  }
  return e.keyCode === keyCode;
}

$(document).on('keydown.quick_submit', '.js-quick-submit', (e) => {
  // Enter
  if (!keyCodeIs(e, 13)) {
    return;
  }

  const onlyMeta = e.metaKey && !e.altKey && !e.ctrlKey && !e.shiftKey;
  const onlyCtrl = e.ctrlKey && !e.altKey && !e.metaKey && !e.shiftKey;
  if (!onlyMeta && !onlyCtrl) {
    return;
  }

  e.preventDefault();
  const $form = $(e.target).closest('form');
  const $submitButton = $form.find('input[type=submit], button[type=submit]').first();

  if (!$submitButton.prop('disabled')) {
    $submitButton.trigger('click', [e]);

    if (!isInIssuePage()) {
      $submitButton.disable();
    }
  }
});

// If the user tabs to a submit button on a `js-quick-submit` form, display a
// tooltip to let them know they could've used the hotkey
$(document).on('keyup.quick_submit', '.js-quick-submit input[type=submit], .js-quick-submit button[type=submit]', function displayTooltip(e) {
  // Tab
  if (!keyCodeIs(e, 9)) {
    return;
  }

  const $this = $(this);
  const title = isMac() ?
    'You can also press &#8984;-Enter' :
    'You can also press Ctrl-Enter';

  $this.tooltip({
    container: 'body',
    html: 'true',
    placement: 'auto top',
    title,
    trigger: 'manual',
  });
  $this.tooltip('show').one('blur click', () => $this.tooltip('hide'));
});
