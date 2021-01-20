import DirtySubmitCollection from '~/dirty_submit/dirty_submit_collection';
import { setInputValue, createForm } from './helper';

jest.mock('lodash/throttle', () => jest.fn((fn) => fn));

describe('DirtySubmitCollection', () => {
  const testElementsCollection = [createForm(), createForm()];
  const forms = testElementsCollection.map((testElements) => testElements.form);

  new DirtySubmitCollection(forms); // eslint-disable-line no-new

  it.each(testElementsCollection)('disables submits until there are changes', (testElements) => {
    const { input, submit } = testElements;
    const originalValue = input.value;

    expect(submit.disabled).toBe(true);
    setInputValue(input, `${originalValue} changes`);
    expect(submit.disabled).toBe(false);
    setInputValue(input, originalValue);
    expect(submit.disabled).toBe(true);
  });
});
