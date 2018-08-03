/* eslint-disable import/prefer-default-export */
/**
 *
 * Sets the text content of a DOM element to a given value.
 * If the given value is an integer,
 *  the text content will set to the value and will be shown.
 * If the given value is not an integer,
 *  the text content will be emptied and the element will be hidden.
 *
 * The visibility of the element is based on the helper class `.hidden`
 *
 * @param selector {String} selector of the DOM element
 * @param count {Number=} value for the DOM element
 */
export const updateBadgeCount = (selector, count) => {
  const badge = document.querySelector(selector);
  if (Number.isInteger(count)) {
    badge.textContent = `${count}`;
    badge.classList.remove('hidden');
  } else {
    badge.classList.add('hidden');
    badge.textContent = '';
  }
};
