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
