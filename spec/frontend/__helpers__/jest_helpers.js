/*
@module

This method provides convenience functions to help migrating from Karma/Jasmine to Jest.

Try not to use these in new tests - this module is provided primarily for convenience of migrating tests.
 */

/**
 * Creates a plain JS object pre-populated with Jest spy functions. Useful for making simple mocks classes.
 *
 * @see https://jasmine.github.io/2.0/introduction.html#section-Spies:_%3Ccode%3EcreateSpyObj%3C/code%3E
 * @param {string} baseName Human-readable name of the object. This is used for reporting purposes.
 * @param methods {string[]} List of method names that will be added to the spy object.
 */
export function createSpyObj(baseName, methods) {
  const obj = {};
  methods.forEach((method) => {
    obj[method] = jest.fn().mockName(`${baseName}#${method}`);
  });
  return obj;
}
