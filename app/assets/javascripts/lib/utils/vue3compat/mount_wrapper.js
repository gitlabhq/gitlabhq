/**
 * Vue 2 `new Vue({ el })` REPLACES the mount element, while Vue 3
 * `createApp(...).mount(el)` renders INTO it. These helpers emulate the
 * Vue 2 replace semantics for Vue 3 mounts so that both runtimes produce
 * the same DOM: mount into a temporary `display: contents` wrapper appended
 * to the target element, then swap the target element with the rendered
 * nodes.
 *
 * Used by the `new Vue` compat shim (./vue.js) and by `initVueApp`
 * (./init_vue_app.js). Keep every Vue 3 mount path on this single
 * implementation so the mount semantics cannot drift.
 */

/**
 * Creates the wrapper element the Vue 3 app should be mounted into.
 *
 * @param {Element} targetEl - The element the app root will eventually replace.
 * @returns {HTMLDivElement}
 */
export function createMountWrapper(targetEl) {
  const wrapperEl = document.createElement('div');
  wrapperEl.style.display = 'contents';
  wrapperEl.dataset.info = 'gitlab-vue3-compat-wrapper';
  // We need to have it in real HTML otherwise accessing for example attached CSS vars might fail
  targetEl.appendChild(wrapperEl);
  return wrapperEl;
}

/**
 * Replaces the target element with everything the app rendered into the
 * wrapper, marking rendered element roots with `data-gitlab-vue3-app`.
 *
 * @param {Element} targetEl - The element passed to createMountWrapper.
 * @param {Element} wrapperEl - The wrapper returned by createMountWrapper.
 * @param {string} [appName] - Name of the app, used for the data attribute.
 */
export function replaceWithMountWrapperContents(targetEl, wrapperEl, appName) {
  const fragment = new DocumentFragment();

  // Mark Vue 3 apps in production
  for (const node of wrapperEl.childNodes) {
    if (node.nodeType === Node.ELEMENT_NODE) {
      // Can be located with `document.querySelectorAll('[data-gitlab-vue3-app]')`
      node.dataset.gitlabVue3App = appName || '';
    }
  }

  fragment.replaceChildren(...wrapperEl.childNodes);
  targetEl.replaceWith(fragment);
}
