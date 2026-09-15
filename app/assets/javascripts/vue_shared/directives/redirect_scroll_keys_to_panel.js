import {
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  PAGE_DOWN_KEY,
  PAGE_UP_KEY,
  HOME_KEY,
  END_KEY,
} from '~/lib/utils/keys';
import { getDefaultScrollingPanel } from '~/lib/utils/panels';

const SCROLL_KEYS = [ARROW_DOWN_KEY, ARROW_UP_KEY, PAGE_DOWN_KEY, PAGE_UP_KEY, HOME_KEY, END_KEY];

// Controls that use these keys themselves (text entry, listboxes, buttons that
// open dropdowns on ArrowDown, etc.). When the key event comes from one of
// these we must not hijack it. The bound element (e.g. the top bar or a panel
// header) may itself be focusable, or the focus may be on a non-interactive
// child such as a header link.
const INTERACTIVE_SELECTOR =
  'button, input, select, textarea, [contenteditable="true"], [role="listbox"], [role="option"], [role="combobox"], [role="textbox"], [role="menu"], [role="menuitem"]';

// While the bound element (or a non-interactive child of it) is focused, e.g.
// the autofocused top bar on page load or an autofocused panel header link,
// redirect scroll keys to the page's scrolling panel. Moving focus to the panel
// is enough: keyboard scrolling is the browser's default action for the
// keydown, and that default action is applied to whatever element is focused
// when the handler returns (see the UI Events key event order spec), so the
// browser scrolls the panel natively, respecting OS/browser increments.
const onKeydown = (event) => {
  if (!SCROLL_KEYS.includes(event.key)) return;
  if (event.target.closest(INTERACTIVE_SELECTOR)) return;

  const panel = getDefaultScrollingPanel();
  if (!panel) return;

  // Most browsers make scroll containers keyboard-focusable, but not all (e.g.
  // Safari). Make the panel focusable just for this keypress and remove the
  // attribute again on blur, so it never lingers as a click-focusable target
  // that would steal focus and break dropdowns.
  if (!panel.hasAttribute('tabindex')) {
    panel.setAttribute('tabindex', '-1');
    panel.addEventListener('blur', () => panel.removeAttribute('tabindex'), { once: true });
  }

  panel.focus();
};

/**
 * Redirect scroll behavior keys to the relevant panel scroll container.
 *
 * Only use on elements with a small number of descendants, like panel headers,
 * to reduce the chance of interfering with other keyboard behaviors.
 */
export const RedirectScrollKeysToPanelDirective = {
  bind(el) {
    el.addEventListener('keydown', onKeydown);
  },
  unbind(el) {
    el.removeEventListener('keydown', onKeydown);
  },
};
