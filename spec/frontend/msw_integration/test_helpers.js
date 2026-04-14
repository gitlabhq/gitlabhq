import { waitFor } from '@testing-library/dom';

export const waitForElement = (finder) =>
  waitFor(() => {
    const element = finder();
    expect(element).not.toBe(null);
    return element;
  });

/**
 * Returns the text content of a DOM element with normalized whitespace.
 * Equivalent to VTU's `.text()` method — collapses all whitespace runs
 * into a single space and trims leading/trailing whitespace.
 * @param {HTMLElement} el
 * @returns {string}
 */
export function getText(el) {
  return el.textContent.replace(/\s+/g, ' ').trim();
}
