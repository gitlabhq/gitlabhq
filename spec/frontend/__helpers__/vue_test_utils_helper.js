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
            return createWrapper(elements[0], this.options);
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
              const elementWrapper = createWrapper(element, this.options);
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
