import { shallowMount } from '@vue/test-utils';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import TextWidget from '~/pipeline_wizard/components/widgets/text.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

describe('Pipeline Wizard - Text Widget', () => {
  const defaultProps = {
    label: 'This label',
    description: 'some description',
    placeholder: 'some placeholder',
    pattern: '^[a-z]+$',
    invalidFeedback: 'some feedback',
  };

  let wrapper;

  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findGlFormGroupInvalidFeedback = () => findGlFormGroup().find('.invalid-feedback');
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);

  const createComponent = (props = {}, mountFn = mountExtended) => {
    wrapper = mountFn(TextWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('creates an input element with the correct label', () => {
    createComponent();

    expect(wrapper.findByLabelText(defaultProps.label).exists()).toBe(true);
  });

  it('uses monospace font for input', () => {
    createComponent({ monospace: true }, shallowMount);

    expect(findGlFormInput().attributes('class')).toBe('!gl-font-monospace');
  });

  it('passes the description', () => {
    createComponent({}, shallowMount);

    expect(findGlFormGroup().attributes('description')).toBe(defaultProps.description);
  });

  it('sets the "text" type on the input component', () => {
    createComponent();

    expect(findGlFormInput().attributes('type')).toBe('text');
  });

  it('passes the placeholder', () => {
    createComponent();

    expect(findGlFormInput().attributes('placeholder')).toBe(defaultProps.placeholder);
  });

  it('emits an update event on input', async () => {
    createComponent();

    const localValue = 'somevalue';
    await findGlFormInput().setValue(localValue);

    expect(wrapper.emitted('input')).toEqual([[localValue]]);
  });

  it('passes invalid feedback message', () => {
    createComponent();

    expect(findGlFormGroupInvalidFeedback().text()).toBe(defaultProps.invalidFeedback);
  });

  it('provides invalid feedback', async () => {
    createComponent({ validate: true });

    await findGlFormInput().setValue('invalid%99');

    expect(findGlFormGroup().classes()).toContain('is-invalid');
    expect(findGlFormInput().classes()).toContain('is-invalid');
  });

  it('provides valid feedback', async () => {
    createComponent({ validate: true });

    await findGlFormInput().setValue('valid');

    expect(findGlFormGroup().classes()).toContain('is-valid');
    expect(findGlFormInput().classes()).toContain('is-valid');
  });

  it('does not show validation state when untouched', () => {
    createComponent({ value: 'invalid99' });

    expect(findGlFormGroup().classes()).not.toContain('is-valid');
    expect(findGlFormGroup().classes()).not.toContain('is-invalid');
  });

  it('shows invalid state on blur', async () => {
    createComponent();

    await findGlFormInput().setValue('invalid%99');

    expect(findGlFormGroup().classes()).not.toContain('is-invalid');

    await findGlFormInput().trigger('blur');

    expect(findGlFormInput().classes()).toContain('is-invalid');
    expect(findGlFormGroup().classes()).toContain('is-invalid');
  });

  it('shows invalid state when toggling `validate` prop', async () => {
    createComponent({
      required: true,
      validate: false,
    });

    expect(findGlFormGroup().classes()).not.toContain('is-invalid');

    await wrapper.setProps({ validate: true });

    expect(findGlFormGroup().classes()).toContain('is-invalid');
  });

  it('does not update validation if not required', () => {
    createComponent({
      pattern: null,
      validate: true,
    });

    expect(findGlFormGroup().classes()).not.toContain('is-invalid');
  });

  it('sets default value', () => {
    const defaultValue = 'foo';
    createComponent({
      default: defaultValue,
    });

    expect(wrapper.findByLabelText(defaultProps.label).element.value).toBe(defaultValue);
  });

  it('emits default value on setup', () => {
    const defaultValue = 'foo';
    createComponent({
      default: defaultValue,
    });

    expect(wrapper.emitted('input')).toEqual([[defaultValue]]);
  });
});
