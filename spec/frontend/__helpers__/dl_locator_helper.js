import { createWrapper, ErrorWrapper } from '@vue/test-utils';

/**
 * Find the definition (<dd>) that corresponds to this term (<dt>)
 *
 * Given html in the `wrapper`:
 *
 * <dl>
 *   <dt>My label</dt>
 *   <dd>Value</dd>
 * </dl>
 *
 * findDd('My label', wrapper)
 *
 * Returns `<dd>Value</dd>`
 *
 * @param {object} wrapper - Parent wrapper
 * @param {string} dtLabel - Label for this value
 * @returns Wrapper
 */
export const findDd = (dtLabel, wrapper) => {
  const dt = wrapper.findByText(dtLabel).element;
  const dd = dt.nextElementSibling;
  if (dt.tagName === 'DT' && dd.tagName === 'DD') {
    return createWrapper(dd, {});
  }
  return ErrorWrapper(dtLabel);
};
