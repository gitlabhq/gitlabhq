import { memoize } from 'lodash';
import axios from '~/lib/utils/axios_utils';

/**
 * Resolves to a DOM that contains GitLab icons
 * in svg format. Memoized to avoid duplicate requests
 */
const getSvgDom = memoize(() =>
  axios
    .get(gon.sprite_icons)
    .then(({ data: svgs }) => new DOMParser().parseFromString(svgs, 'text/xml'))
    .catch(e => {
      getSvgDom.cache.clear();

      throw e;
    }),
);

/**
 * Clears the memoized SVG content.
 *
 * You probably don't need to invoke this function unless
 * sprite_icons are updated.
 */
export const clearSvgIconPathContentCache = () => {
  getSvgDom.cache.clear();
};

/**
 * Retrieve SVG icon path content from gitlab/svg sprite icons.
 *
 * Content loaded is cached.
 *
 * @param {String} name - Icon name
 * @returns A promise that resolves to the svg path
 */
export const getSvgIconPathContent = name =>
  getSvgDom()
    .then(doc => {
      return doc.querySelector(`#${name} path`).getAttribute('d');
    })
    .catch(() => null);
