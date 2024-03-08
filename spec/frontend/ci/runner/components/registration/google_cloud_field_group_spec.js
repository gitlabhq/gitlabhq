import { mountExtended } from 'helpers/vue_test_utils_helper';

import GoogleCloudFieldGroup from '~/ci/runner/components/registration/google_cloud_field_group.vue';

describe('GoogleCloudRegistrationInstructions', () => {
  let wrapper;

  const findLabel = () => wrapper.find('label');
  const findInput = () => wrapper.find('input');

  const createComponent = ({ props = {}, ...options } = {}) => {
    wrapper = mountExtended(GoogleCloudFieldGroup, {
      propsData: {
        name: 'field',
        ...props,
      },
      ...options,
    });
  };

  const changeValue = (textInput, value) => {
    // eslint-disable-next-line no-param-reassign
    textInput.element.value = value;
    return textInput.trigger('change');
  };

  it('shows a form label and field', () => {
    createComponent({
      props: { label: 'My field', name: 'myField' },
    });

    expect(findLabel().attributes('for')).toBe('myField');
    expect(findLabel().text()).toBe('My field');

    expect(findInput().attributes()).toMatchObject({
      id: 'myField',
      name: 'myField',
      type: 'text',
    });
  });

  it('accepts a value without updating it', () => {
    createComponent({
      props: { value: { state: true, value: 'Prefilled' } },
    });

    expect(findInput().element.value).toEqual('Prefilled');
    expect(wrapper.emitted('change')).toBeUndefined();
  });

  it('accepts arbitrary slots', () => {
    createComponent({
      slots: {
        label: '<strong>Label</strong>',
        description: '<div>Description</div>',
      },
    });

    expect(findLabel().html()).toContain('<strong>Label</strong>');
    expect(wrapper.html()).toContain('<div>Description</div>');
  });

  describe('field validation', () => {
    beforeEach(() => {
      createComponent({
        props: {
          regexp: /^[a-z][0-9]$/,
          invalidFeedbackIfEmpty: 'Field is required.',
          invalidFeedbackIfMalformed: 'Field is incorrect.',
        },
      });
    });

    it('validates a missing value', async () => {
      await changeValue(findInput(), '');

      expect(wrapper.emitted('change')).toEqual([[{ state: false, value: '' }]]);
      expect(wrapper.text()).toBe('Field is required.');
      expect(findInput().attributes('aria-invalid')).toBe('true');
    });

    it('validates a wrong value', async () => {
      await changeValue(findInput(), '11');

      expect(wrapper.emitted('change')).toEqual([[{ state: false, value: '11' }]]);
      expect(wrapper.text()).toBe('Field is incorrect.');
      expect(findInput().attributes('aria-invalid')).toBe('true');
    });

    it('validates a correct value', async () => {
      await changeValue(findInput(), 'a1');

      expect(wrapper.emitted('change')).toEqual([[{ state: true, value: 'a1' }]]);
      expect(wrapper.text()).toBe('');
      expect(findInput().attributes('aria-invalid')).toBeUndefined();
    });
  });
});
