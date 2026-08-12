import { visitUrl } from './url_utility';

let registeredNavShortcutLinks = null;

/**
 * Registers navigation menu items as fallback targets for keyboard shortcuts
 * when the items are not rendered in the DOM. Every findAndFollowLink and
 * findAndFollowChildLink caller consults this fallback, but only when its
 * selector has no match in the rendered DOM; rendered matches always win.
 * Reusing the serialized menu items avoids extending the hidden-anchor
 * pattern in super_sidebar.vue, which would duplicate nav item URLs in a
 * second hand-maintained server-side list.
 *
 * @param {Array} menuItems Serialized sidebar menu items ({ link, link_classes, items }).
 */
export function registerNavShortcutLinks(menuItems) {
  registeredNavShortcutLinks = document.createElement('div');

  const addItem = (item) => {
    if (item.link && item.link_classes) {
      const anchor = document.createElement('a');
      anchor.setAttribute('href', item.link);
      anchor.className = item.link_classes;
      registeredNavShortcutLinks.appendChild(anchor);
    }
    item.items?.forEach(addItem);
  };
  menuItems.forEach(addItem);
}

function findShortcutElement(selector) {
  return document.querySelector(selector) || registeredNavShortcutLinks?.querySelector(selector);
}

/**
 * Helper function that finds the href of the given selector and updates the location.
 *
 * @param  {String} selector
 */
export default function findAndFollowLink(selector) {
  const element = findShortcutElement(selector);
  const link = element && element.getAttribute('href');

  if (link) {
    visitUrl(link);
  }
}

/**
 * Helper function that finds the href of the direct child element of given selector and updates the location.
 *
 * @param  {String} selector
 */
export function findAndFollowChildLink(selector) {
  const element = findShortcutElement(selector);
  const parentLink = element && element.getAttribute('href');

  const childLink = element?.firstElementChild && element.firstElementChild.getAttribute('href');

  if (parentLink) {
    findAndFollowLink(selector);
  } else if (childLink) {
    visitUrl(childLink);
  }
}

export function prefetchDocument(url) {
  const newPrefetchLink = document.createElement('link');
  newPrefetchLink.rel = 'prefetch';
  newPrefetchLink.href = url;
  newPrefetchLink.setAttribute('as', 'document');
  document.head.appendChild(newPrefetchLink);
}

export function initPrefetchLinks(selector) {
  document.querySelectorAll(selector).forEach((el) => {
    let mouseOverTimer;

    const mouseOutHandler = () => {
      if (mouseOverTimer) {
        clearTimeout(mouseOverTimer);
        mouseOverTimer = undefined;
      }
    };

    const mouseOverHandler = () => {
      el.addEventListener('mouseout', mouseOutHandler, { once: true, passive: true });

      mouseOverTimer = setTimeout(() => {
        if (el.href) prefetchDocument(el.href);

        // Only execute once
        el.removeEventListener('mouseover', mouseOverHandler, true);

        mouseOverTimer = undefined;
      }, 100);
    };

    el.addEventListener('mouseover', mouseOverHandler, {
      capture: true,
      passive: true,
    });
  });
}
