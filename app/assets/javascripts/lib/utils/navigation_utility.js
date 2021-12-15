import { visitUrl } from './url_utility';

/**
 * Helper function that finds the href of the fiven selector and updates the location.
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
