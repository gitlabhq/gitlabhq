export function loadCSSFile(path) {
  return new Promise((resolve) => {
    if (!path) resolve();

    if (document.querySelector(`link[href="${path}"]`)) {
      resolve();
    } else {
      const linkElement = document.createElement('link');
      linkElement.type = 'text/css';
      linkElement.rel = 'stylesheet';
      // eslint-disable-next-line @gitlab/require-i18n-strings
      linkElement.media = 'screen,print';
      linkElement.onload = () => {
        resolve();
      };
      linkElement.href = path;

      document.head.appendChild(linkElement);
    }
  });
}

export function getCssVariable(variable) {
  return getComputedStyle(document.documentElement).getPropertyValue(variable).trim();
}

/**
 * Return the measured width and height of a temporary element with the given
 * CSS classes.
 *
 * Multiple classes can be given by separating them with spaces.
 *
 * Since this forces a layout calculation, do not call this frequently or in
 * loops.
 *
 * Finally, this assumes the styles for the given classes are loaded.
 *
 * @param {string} className CSS class(es) to apply to a temporary element and
 *     measure.
 * @returns {{ width: number, height: number }} Measured width and height in
 *     CSS pixels.
 */
export function getCssClassDimensions(className) {
  const el = document.createElement('div');
  el.className = className;
  document.body.appendChild(el);
  const { width, height } = el.getBoundingClientRect();
  el.remove();
  return { width, height };
}
