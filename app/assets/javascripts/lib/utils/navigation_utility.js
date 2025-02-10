import { visitUrl } from './url_utility';

/**
 * Helper function that finds the href of the given selector and updates the location.
 *
 * @param  {String} selector
 */
export default function findAndFollowLink(selector) {
  const element = document.querySelector(selector);
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
  const element = document.querySelector(selector);
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
