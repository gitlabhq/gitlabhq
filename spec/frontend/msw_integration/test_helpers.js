import { waitFor, screen, within } from '@testing-library/vue';
import { mount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';

export { screen, within };

export const assignRouter = (routerFn, args) => {
  setWindowLocation(args?.routerPath || '/');

  const router = routerFn(args);

  // We inject the router metadata globally so that our test setup can
  // pick it up and do the router setup and cleanup
  global.metadata = { ...global.metadata, router };
  return router;
};

export const fullMount = (component, params) => {
  return mount(component, { attachTo: document.body, ...params });
};

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

/**
 * Finds a button element by its text content or aria-label.
 * Uses @testing-library/vue's queryAllByRole under the hood,
 * returning the first match or null.
 * @param {string} text - The text content or aria-label to search for
 * @param {HTMLElement} [container=document.body] - The container to search within
 * @returns {HTMLElement|null}
 */
export function findButtonByText(text, container = document.body) {
  const matches = within(container).queryAllByRole('button', { name: text });
  return matches[0] || null;
}

/**
 * Sets the value of an input element and dispatches the appropriate event.
 * @param {HTMLElement} input - The input element
 * @param {string} value - The value to set
 * @param {string} [eventType='input'] - The event type to dispatch ('input', 'change', etc.)
 */
export function setInputValue(input, value, eventType = 'input') {
  // eslint-disable-next-line no-param-reassign
  input.value = value;
  input.dispatchEvent(new Event(eventType, { bubbles: true }));
}

/**
 * Waits for an element to appear, then clicks it.
 * @param {Function} finder - A function that returns the element to click
 * @returns {Promise<HTMLElement>}
 */
export async function waitAndClick(finder) {
  const element = await waitForElement(finder);
  element.click();
  return element;
}

/**
 * Waits for an element to appear, then sets its value.
 * @param {Function} finder - A function that returns the input element
 * @param {string} value - The value to set
 * @param {string} [eventType='input'] - The event type to dispatch
 * @returns {Promise<HTMLElement>}
 */
export async function waitAndSetValue(finder, value, eventType = 'input') {
  const element = await waitForElement(finder);
  setInputValue(element, value, eventType);
  return element;
}

/**
 * Waits for an element to disappear (become null).
 * @param {Function} finder - A function that returns the element
 * @returns {Promise<void>}
 */
export function waitForElementToBeNull(finder) {
  return waitFor(() => {
    expect(finder()).toBe(null);
  });
}

/**
 * Finds an element by its GraphQL ID.
 * Converts GraphQL ID to numeric ID and finds the corresponding issuable element.
 * @param {string} graphqlId - The GraphQL ID (e.g., 'gid://gitlab/WorkItem/123')
 * @param {Function} getIdFromGraphQLId - Function to extract numeric ID from GraphQL ID
 * @returns {HTMLElement|null}
 */
export function findByGraphQLId(graphqlId, getIdFromGraphQLId, elementPrefix = 'issuable_') {
  const numericId = getIdFromGraphQLId(graphqlId);
  return document.querySelector(`#${elementPrefix}${numericId}`);
}

/**
 * Waits for a condition to be true with a custom assertion.
 * @param {Function} assertion - A function that performs the assertion
 * @returns {Promise<void>}
 */
export function waitForAssertion(assertion) {
  return waitFor(() => {
    assertion();
  });
}
