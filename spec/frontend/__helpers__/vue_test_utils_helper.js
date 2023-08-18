import * as testingLibrary from '@testing-library/dom';
import {
  createWrapper,
  Wrapper, // eslint-disable-line no-unused-vars
  ErrorWrapper,
  mount,
  shallowMount,
  WrapperArray,
} from '@vue/test-utils';
import { compose } from 'lodash/fp';

const vNodeContainsText = (vnode, text) =>
  (vnode.text && vnode.text.includes(text)) ||
  (vnode.children && vnode.children.filter((child) => vNodeContainsText(child, text)).length);

/**
 * Create a VTU wrapper from an element.
 *
 * If a Vue instance manages the element, the wrapper is created
 * with that Vue instance.
 *
 * @param {HTMLElement} element
 * @param {Object} options
 * @returns {Wrapper} VTU wrapper
 */
const createWrapperFromElement = (element, options) =>
  // eslint-disable-next-line no-underscore-dangle
  createWrapper(element.__vue__ || element, options || {});

/**
 * Determines whether a `shallowMount` Wrapper contains text
 * within one of it's slots. This will also work on Wrappers
 * acquired with `find()`, but only if it's parent Wrapper
 * was shallowMounted.
 * NOTE: Prefer checking the rendered output of a component
 * wherever possible using something like `text()` instead.
 * @param {Wrapper} shallowWrapper - Vue test utils wrapper (shallowMounted)
 * @param {String} slotName
 * @param {String} text
 */
export const shallowWrapperContainsSlotText = (shallowWrapper, slotName, text) =>
  Boolean(
    shallowWrapper.vm.$slots[slotName].filter((vnode) => vNodeContainsText(vnode, text)).length,
  );

/**
 * Returns a promise that waits for a mutation to be fired before resolving
 * NOTE: There's no reject action here so it will hang if it waits for a mutation that won't happen.
 * @param {Object} store - The Vue store that contains the mutations
 * @param {String} expectedMutationType - The Mutation to wait for
 */
export const waitForMutation = (store, expectedMutationType) =>
  new Promise((resolve) => {
    const unsubscribe = store.subscribe((mutation) => {
      if (mutation.type === expectedMutationType) {
        unsubscribe();
        resolve();
      }
    });
  });

/**
 * Query function type
 * @callback FindFunction
 * @param text
 * @returns {Wrapper}
 */

/**
 * Query all function type
 * @callback FindAllFunction
 * @param text
 * @returns {WrapperArray}
 */

/**
 * Query find with options functions type
 * @callback FindWithOptionsFunction
 * @param text
 * @param options
 * @returns {Wrapper}
 */

/**
 * Query find all with options functions type
 * @callback FindAllWithOptionsFunction
 * @param text
 * @param options
 * @returns {WrapperArray}
 */

/**
 * Extended Wrapper queries
 * @typedef { {
 *   findByTestId: FindFunction,
 *   findAllByTestId: FindAllFunction,
 *   findComponentByTestId: FindFunction,
 *   findAllComponentsByTestId: FindAllFunction,
 *   findByRole: FindWithOptionsFunction,
 *   findAllByRole: FindAllWithOptionsFunction,
 *   findByLabelText: FindWithOptionsFunction,
 *   findAllByLabelText: FindAllWithOptionsFunction,
 *   findByPlaceholderText: FindWithOptionsFunction,
 *   findAllByPlaceholderText: FindAllWithOptionsFunction,
 *   findByText: FindWithOptionsFunction,
 *   findAllByText: FindAllWithOptionsFunction,
 *   findByDisplayValue: FindWithOptionsFunction,
 *   findAllByDisplayValue: FindAllWithOptionsFunction,
 *   findByAltText: FindWithOptionsFunction,
 *   findAllByAltText: FindAllWithOptionsFunction,
 *   findByTitle: FindWithOptionsFunction,
 *   findAllByTitle: FindAllWithOptionsFunction
 * } } ExtendedQueries
 */

/**
 * Extended Wrapper
 * @typedef {(Wrapper & ExtendedQueries)} ExtendedWrapper
 */

/**
 * Creates a Wrapper {@link https://v1.test-utils.vuejs.org/api/wrapper/} with
 * Additional Queries {@link https://testing-library.com/docs/queries/about}.
 * @param { Wrapper } wrapper
 * @returns { ExtendedWrapper }
 */
export const extendedWrapper = (wrapper) => {
  // https://testing-library.com/docs/queries/about
  const AVAILABLE_QUERIES = [
    'ByRole',
    'ByLabelText',
    'ByPlaceholderText',
    'ByText',
    'ByDisplayValue',
    'ByAltText',
    'ByTitle',
  ];

  if (Array.isArray(wrapper) || !wrapper?.find) {
    // eslint-disable-next-line no-console
    console.warn(
      '[vue-test-utils-helper]: you are trying to extend an object that is not a VueWrapper.',
    );
    return wrapper;
  }

  return Object.defineProperties(wrapper, {
    findByTestId: {
      /** @this { Wrapper } */
      value(id) {
        return this.find(`[data-testid="${id}"]`);
      },
    },
    findAllByTestId: {
      /** @this { Wrapper } */
      value(id) {
        return this.findAll(`[data-testid="${id}"]`);
      },
    },
    /*
     * Keep in mind that there are some limitations when using `findComponent`
     * with CSS selectors: https://v1.test-utils.vuejs.org/api/wrapper/#findcomponent
     */
    findComponentByTestId: {
      /** @this { Wrapper } */
      value(id) {
        return this.findComponent(`[data-testid="${id}"]`);
      },
    },
    /*
     * Keep in mind that there are some limitations when using `findAllComponents`
     * with CSS selectors: https://v1.test-utils.vuejs.org/api/wrapper/#findallcomponents
     */
    findAllComponentsByTestId: {
      /** @this { Wrapper } */
      value(id) {
        return this.findAllComponents(`[data-testid="${id}"]`);
      },
    },
    // `findBy`
    ...AVAILABLE_QUERIES.reduce((accumulator, query) => {
      return {
        ...accumulator,
        [`find${query}`]: {
          /** @this { Wrapper } */
          value(text, options = {}) {
            const elements = testingLibrary[`queryAll${query}`](this.element, text, options);

            // Element not found, return an `ErrorWrapper`
            if (!elements.length) {
              return new ErrorWrapper(query);
            }
            return createWrapperFromElement(elements[0], this.options);
          },
        },
      };
    }, {}),
    // `findAllBy`
    ...AVAILABLE_QUERIES.reduce((accumulator, query) => {
      return {
        ...accumulator,
        [`findAll${query}`]: {
          /** @this { Wrapper } */
          value(text, options = {}) {
            const elements = testingLibrary[`queryAll${query}`](this.element, text, options);

            const wrappers = elements.map((element) => {
              const elementWrapper = createWrapperFromElement(element, this.options);
              elementWrapper.selector = text;

              return elementWrapper;
            });

            const wrapperArray = new WrapperArray(wrappers);
            wrapperArray.selector = text;

            return wrapperArray;
          },
        },
      };
    }, {}),
  });
};

export const shallowMountExtended = compose(extendedWrapper, shallowMount);
export const mountExtended = compose(extendedWrapper, mount);
