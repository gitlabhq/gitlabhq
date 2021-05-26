import * as testingLibrary from '@testing-library/dom';
import { createWrapper, WrapperArray, ErrorWrapper, mount, shallowMount } from '@vue/test-utils';
import { isArray, upperFirst } from 'lodash';

const vNodeContainsText = (vnode, text) =>
  (vnode.text && vnode.text.includes(text)) ||
  (vnode.children && vnode.children.filter((child) => vNodeContainsText(child, text)).length);

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

export const extendedWrapper = (wrapper) => {
  // https://testing-library.com/docs/queries/about
  const AVAILABLE_QUERIES = [
    'byRole',
    'byLabelText',
    'byPlaceholderText',
    'byText',
    'byDisplayValue',
    'byAltText',
    'byTitle',
  ];

  if (isArray(wrapper) || !wrapper?.find) {
    // eslint-disable-next-line no-console
    console.warn(
      '[vue-test-utils-helper]: you are trying to extend an object that is not a VueWrapper.',
    );
    return wrapper;
  }

  return Object.defineProperties(wrapper, {
    findByTestId: {
      value(id) {
        return this.find(`[data-testid="${id}"]`);
      },
    },
    findAllByTestId: {
      value(id) {
        return this.findAll(`[data-testid="${id}"]`);
      },
    },
    // `findBy`
    ...AVAILABLE_QUERIES.reduce((accumulator, query) => {
      return {
        ...accumulator,
        [`find${upperFirst(query)}`]: {
          value(text, options = {}) {
            const elements = testingLibrary[`queryAll${upperFirst(query)}`](
              wrapper.element,
              text,
              options,
            );

            // Element not found, return an `ErrorWrapper`
            if (!elements.length) {
              return new ErrorWrapper(query);
            }

            return createWrapper(elements[0], this.options || {});
          },
        },
      };
    }, {}),
    // `findAllBy`
    ...AVAILABLE_QUERIES.reduce((accumulator, query) => {
      return {
        ...accumulator,
        [`findAll${upperFirst(query)}`]: {
          value(text, options = {}) {
            const elements = testingLibrary[`queryAll${upperFirst(query)}`](
              wrapper.element,
              text,
              options,
            );

            const wrappers = elements.map((element) => {
              const elementWrapper = createWrapper(element, this.options || {});
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

export const shallowMountExtended = (...args) => extendedWrapper(shallowMount(...args));

export const mountExtended = (...args) => extendedWrapper(mount(...args));
