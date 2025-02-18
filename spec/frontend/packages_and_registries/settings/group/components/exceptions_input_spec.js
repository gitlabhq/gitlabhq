import { GlSprintf, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/settings/group/components/exceptions_input.vue';

import { DUPLICATES_SETTING_EXCEPTION_TITLE } from '~/packages_and_registries/settings/group/constants';

describe('Exceptions Input', () => {
  let wrapper;

  const defaultProps = {
    duplicateExceptionRegex: 'foo',
    id: 'maven-duplicated-settings-regex-input',
    name: 'exceptionModel',
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findInput = () => wrapper.findComponent(GlFormInput);

  it('shows a form group with an input field', () => {
    mountComponent();

    expect(findInputGroup().exists()).toBe(true);

    expect(findInputGroup().attributes()).toMatchObject({
      'label-for': defaultProps.id,
      label: DUPLICATES_SETTING_EXCEPTION_TITLE,
      'label-sr-only': '',
    });
  });

  it('shows an input field', () => {
    mountComponent();

    expect(findInput().exists()).toBe(true);

    expect(findInput().attributes()).toMatchObject({
      id: 'maven-duplicated-settings-regex-input',
      value: defaultProps.duplicateExceptionRegex,
    });
  });

  it('input change event emits an update event', () => {
    mountComponent();

    findInput().vm.$emit('change', 'bar');

    expect(wrapper.emitted('update')).toStrictEqual([[{ [defaultProps.name]: 'bar' }]]);
  });

  describe('valid state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('form group has correct props', () => {
      expect(findInputGroup().attributes('input-feedback')).toBeUndefined();
    });

    it('form input has correct props', () => {
      expect(findInput().attributes('state')).toBe('true');
    });
  });

  describe('invalid state', () => {
    const propsWithError = {
      ...defaultProps,
      duplicateExceptionRegexError: 'some error string',
    };

    beforeEach(() => {
      mountComponent(propsWithError);
    });

    it('form group has correct props', () => {
      expect(findInputGroup().attributes('invalid-feedback')).toBe(
        propsWithError.duplicateExceptionRegexError,
      );
    });

    it('form input has correct props', () => {
      expect(findInput().attributes('state')).toBeUndefined();
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      mountComponent({ ...defaultProps, loading: true });
    });

    it('disables the form input', () => {
      expect(findInput().attributes('disabled')).toBeDefined();
    });
  });
});
