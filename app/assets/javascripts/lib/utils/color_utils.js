/**
 * Convert hex color to rgb array
 *
 * @param hex string
 * @returns array|null
 */
export const hexToRgb = (hex) => {
  // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  const shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
  const fullHex = hex.replace(shorthandRegex, (_m, r, g, b) => r + r + g + g + b + b);

  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(fullHex);
  return result
    ? [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)]
    : null;
};

export const textColorForBackground = (backgroundColor) => {
  const [r, g, b] = hexToRgb(backgroundColor);

  if (r + g + b > 500) {
    return '#333333';
  }
  return '#FFFFFF';
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
  const isWebIde = document.body.dataset.page.startsWith('ide:');

  if (isWebIde) {
    return ideDarkThemes.includes(window.gon?.user_color_scheme);
  }
  return document.body.classList.contains('gl-dark');
}
