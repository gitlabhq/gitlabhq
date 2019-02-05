/* eslint-disable import/prefer-default-export */

import axios from '~/lib/utils/axios_utils';

/**
 * Retrieve SVG icon path content from gitlab/svg sprite icons
 * @param {String} name
 */
export const getSvgIconPathContent = name =>
  axios
    .get(gon.sprite_icons)
    .then(({ data: svgs }) =>
      new DOMParser()
        .parseFromString(svgs, 'text/xml')
        .querySelector(`#${name} path`)
        .getAttribute('d'),
    )
    .catch(() => null);
