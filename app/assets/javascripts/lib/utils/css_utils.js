import { GL_DARK, GL_LIGHT, GL_SYSTEM } from '~/constants';
import { PREFERS_DARK } from './constants';

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

/**
 * Returns string name of current color scheme based on user preferences.
 * In the case user preference is automatic (gl-system), it will return scheme based on media query.
 *
 * @returns {string} current color scheme (gl-light, gl-dark)
 */
export function getSystemColorScheme() {
  if (gon.user_color_mode === GL_SYSTEM) {
    if (window.matchMedia && window.matchMedia(PREFERS_DARK).matches) {
      return GL_DARK;
    }
    return GL_LIGHT;
  }
  return gon.user_color_mode;
}

/**
 * Handles media query change event and triggers the provided callback.
 *
 * @param {function} onEvent function to be called on system color scheme change
 * @param {MediaQueryListEvent} event the event object from the media query change
 */
function handleColorSchemeChange(onEvent, event) {
  onEvent(event.matches ? GL_DARK : GL_LIGHT);
}

/**
 * Subscribes for media query change of system color scheme.
 * On change triggers function passed in.
 *
 * @param {function} onEvent function to be called on system color scheme change
 * @returns {void}
 */
export function listenSystemColorSchemeChange(onEvent) {
  window
    .matchMedia(PREFERS_DARK)
    .addEventListener('change', (event) => handleColorSchemeChange(onEvent, event));
}

/**
 * Destroys event subscribtion for media query change of system color scheme.
 *
 * @param {function} onEvent function to be called on system color scheme change
 * @returns {void}
 */
export function removeListenerSystemColorSchemeChange(onEvent) {
  window
    .matchMedia(PREFERS_DARK)
    .removeEventListener('change', (event) => handleColorSchemeChange(onEvent, event));
}

function isNarrowScreenMediaQuery() {
  const computedStyles = getComputedStyle(document.body);
  const largeBreakpointSize = parseInt(computedStyles.getPropertyValue('--breakpoint-lg'), 10);
  return window.matchMedia(`(max-width: ${largeBreakpointSize - 1}px)`);
}

export function isNarrowScreen() {
  return isNarrowScreenMediaQuery().matches;
}

export function isNarrowScreenAddListener(handlerFn) {
  isNarrowScreenMediaQuery().addEventListener('change', handlerFn);
}

export function isNarrowScreenRemoveListener(handlerFn) {
  isNarrowScreenMediaQuery().removeEventListener('change', handlerFn);
}
