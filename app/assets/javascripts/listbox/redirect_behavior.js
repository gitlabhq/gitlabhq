import { initListbox } from '~/listbox';
import { visitUrl } from '~/lib/utils/url_utility';

/**
 * Instantiates GlCollapsibleListbox components with redirect behavior for tags created
 * with the `gl_redirect_listbox_tag` HAML helper.
 *
 * NOTE: Do not import this script explicitly. Using `gl_redirect_listbox_tag`
 * automatically injects the `redirect_listbox` bundle, which calls this
 * function.
 */
export function initRedirectListboxBehavior() {
  const elements = Array.from(document.querySelectorAll('.js-redirect-listbox'));

  return elements.map((el) =>
    initListbox(el, {
      onChange({ href }) {
        visitUrl(href);
      },
    }),
  );
}
