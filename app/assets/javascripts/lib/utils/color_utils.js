import { GL_DARK } from '~/constants';
import { getSystemColorScheme } from '~/lib/utils/css_utils';

const colorValidatorEl = document.createElement('div');

/**
 * Validates whether the specified color expression
 * is supported by the browser’s DOM API and has a valid form.
 *
 * This utility assigns the color expression to a detached DOM
 * element’s color property. If the color expression is valid,
 * the DOM API will accept the value.
 *
 * @param {String} colorExpression color expression rgba, hex, hsla, etc.
 */
export const isValidColorExpression = (colorExpression) => {
  colorValidatorEl.style.color = '';
  colorValidatorEl.style.color = colorExpression;

  return colorValidatorEl.style.color.length > 0;
};

/**
 * Check whether a color matches the expected hex format
 *
 * This matches any hex (0-9 and A-F) value which is either 3 or 6 characters in length
 *
 * An empty string will return `null` which means that this is neither valid nor invalid.
 * This is useful for forms resetting the validation state
 *
 * @param color string = ''
 *
 * @returns {null|boolean}
 */
export const validateHexColor = (color = '') => {
  if (!color) {
    return null;
  }

  return /^#([0-9A-F]{3}){1,2}$/i.test(color);
};

export function darkModeEnabled() {
  const ideDarkThemes = ['dark', 'solarized-dark', 'monokai'];

  // eslint-disable-next-line @gitlab/require-i18n-strings
  const isWebIde = document.body.dataset.page?.startsWith('ide:');

  if (isWebIde) {
    return ideDarkThemes.includes(window.gon?.user_color_scheme);
  }
  return document.documentElement.classList.contains('gl-dark');
}

/**
 * Returns an adaptive work item status color based on the current theme mode
 *
 * @param color string = ''
 * @returns {string}
 */
export function getAdaptiveStatusColor(color = '') {
  /**
   * The default status colors in ee/app/models/work_items/statuses/system_defined/status.rb
   * do not provide enough color contrast in dark mode, so we are creating a map for each of the
   * to do, in progress, done, and won't do/duplicate colors to achieve color contrast better
   * than 3:1 in dark mode
   */
  const STATUS_LIGHT_TO_DARK_COLOR_MAP = {
    '#995715': '#D99530',
    '#737278': '#89888D',
    '#1f75cb': '#428FDC',
    '#108548': '#2DA160',
    '#DD2B0E': '#EC5941',
  };
  let adaptiveColor = color;

  if (getSystemColorScheme() === GL_DARK) {
    adaptiveColor = STATUS_LIGHT_TO_DARK_COLOR_MAP[color] ?? color;
  }

  return adaptiveColor;
}

/**
 * Creates a CSS style object with a linear gradient background
 * from the specified color to white at a 315-degree angle.
 *
 * @param {string} color - The starting color for the gradient (any valid CSS color format)
 * @returns {Object} CSS style object with background property
 *
 * @example
 * // Create a gradient from blue to white
 * const style = gradientStyle('#0066cc');
 * // Returns: { background: 'linear-gradient(315deg, #0066cc, white)' }
 *
 * @example
 * // Use with Vue or React components
 * <div :style="gradientStyle('#ff6b6b')">Content</div>
 */
export const gradientStyle = (color) => {
  return { background: `linear-gradient(315deg, ${color}, white)` };
};

/**
 * Creates a CSS style object with a 2px solid border in the specified color.
 *
 * @param {string} color - The border color (any valid CSS color format)
 * @returns {Object} CSS style object with border property
 *
 * @example
 * // Create a red border
 * const style = borderStyle('#ff0000');
 * // Returns: { border: '2px solid #ff0000' }
 *
 * @example
 * // Use with Vue or React components
 * <div :style="borderStyle('rgba(255, 0, 0, 0.5)')">Content</div>
 */
export const borderStyle = (color) => {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return { border: `2px solid ${color}` };
};
