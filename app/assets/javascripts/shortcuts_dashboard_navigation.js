import { visitUrl } from './lib/utils/url_utility';

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
