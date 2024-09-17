import { isInIssuePage } from '~/lib/utils/common_utils';
import { ENTER_KEY, TAB_KEY } from '~/lib/utils/keys';
import { __ } from '~/locale';
import { add, hide, show } from '~/tooltips';

const quickSubmit = (event) => {
  if (event.code !== ENTER_KEY) {
    return;
  }

  const onlyMeta = event.metaKey && !event.altKey && !event.ctrlKey && !event.shiftKey;
  const onlyCtrl = event.ctrlKey && !event.altKey && !event.metaKey && !event.shiftKey;

  if (!(onlyMeta || onlyCtrl)) {
    return;
  }

  const form = event.target.closest('form');
  const button = form.querySelector('input[type=submit], button[type=submit]');

  button.click();

  if (form.checkValidity() && !isInIssuePage()) {
    button.disabled = true;
  }
};

const displayQuickSubmitTooltip = (event) => {
  if (event.code !== TAB_KEY) {
    return;
  }

  const jQueryElement = { 0: event.target };
  const title = navigator.userAgent.match(/Macintosh/)
    ? __('You can also press \u{2318}-Enter')
    : __('You can also press Ctrl-Enter');

  add(jQueryElement, { show: true, title, triggers: 'manual' });
  show(jQueryElement);
  event.target.addEventListener('blur', () => hide(jQueryElement), { once: true });
};

/**
 * When a field of a form with a `js-quick-submit` class receives a "Cmd+Enter" (Mac)
 * or "Ctrl+Enter" (Linux/Windows) key combination, the form is submitted.
 * The submit button is disabled upon form submission.
 *
 * If the user tabs to the submit button on a `js-quick-submit` form, a
 * tooltip is displayed to let them know they could have used the hotkey.
 *
 * @example
 * <form action="/foo" class="js-quick-submit">
 *   <input type="text" />
 *   <textarea></textarea>
 *   <button type="submit" value="Submit" />
 * </form>
 */
export const initQuickSubmit = () => {
  const forms = Array.from(document.querySelectorAll('.js-quick-submit'));
  const buttons = Array.from(
    document.querySelectorAll('.js-quick-submit :is(input[type=submit], button[type=submit])'),
  );

  forms.forEach((form) => form.addEventListener('keydown', quickSubmit));
  buttons.forEach((button) => button.addEventListener('keyup', displayQuickSubmitTooltip));
};
