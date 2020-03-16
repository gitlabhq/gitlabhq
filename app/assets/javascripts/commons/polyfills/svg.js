/**
 * polyfill support for external SVG file references via <use xlink:href>
 * @what polyfill support for external SVG file references via <use xlink:href>
 * @why This is used in our GitLab SVG icon library
 * @browsers Internet Explorer 11
 * @see https://caniuse.com/#feat=mdn-svg_elements_use_external_uri
 * @see https//css-tricks.com/svg-use-external-source/
 */
import svg4everybody from 'svg4everybody';

svg4everybody();
