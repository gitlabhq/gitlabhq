import { GlSprintf, GlToggle, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/settings/group/components/duplicates_settings.vue';

import {
  DUPLICATES_TOGGLE_LABEL,
  DUPLICATES_ALLOWED_ENABLED,
  DUPLICATES_ALLOWED_DISABLED,
  DUPLICATES_SETTING_EXCEPTION_TITLE,
  DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
} from '~/packages_and_registries/settings/group/constants';

describe('Duplicates Settings', () => {
  let wrapper;

  const defaultProps = {
    duplicatesAllowed: false,
    duplicateExceptionRegex: 'foo',
    modelNames: {
      allowed: 'allowedModel',
      exception: 'exceptionModel',
    },
  };

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findToggleLabel = () => wrapper.find('[data-testid="toggle-label"');

  const findInputGroup = () => wrapper.findComponent(GlFormGroup);
  const findInput = () => wrapper.findComponent(GlFormInput);

  it('has a toggle', () => {
    mountComponent();

    expect(findToggle().exists()).toBe(true);
    expect(findToggle().props()).toMatchObject({
      label: DUPLICATES_TOGGLE_LABEL,
      value: defaultProps.duplicatesAllowed,
    });
  });

  it('toggle emits an update event', () => {
    mountComponent();

    findToggle().vm.$emit('change', false);

    expect(wrapper.emitted('update')).toStrictEqual([
      [{ [defaultProps.modelNames.allowed]: false }],
    ]);
  });

  describe('when the duplicates are disabled', () => {
    it('the toggle has the disabled message', () => {
      mountComponent();

      expect(findToggleLabel().exists()).toBe(true);
      expect(findToggleLabel().text()).toMatchInterpolatedText(DUPLICATES_ALLOWED_DISABLED);
    });

    it('shows a form group with an input field', () => {
      mountComponent();

      expect(findInputGroup().exists()).toBe(true);

      expect(findInputGroup().attributes()).toMatchObject({
        'label-for': 'maven-duplicated-settings-regex-input',
        label: DUPLICATES_SETTING_EXCEPTION_TITLE,
        description: DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
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

      expect(wrapper.emitted('update')).toStrictEqual([
        [{ [defaultProps.modelNames.exception]: 'bar' }],
      ]);
    });

    describe('valid state', () => {
      it('form group has correct props', () => {
        mountComponent();

        expect(findInputGroup().attributes()).toMatchObject({
          state: 'true',
          'invalid-feedback': '',
        });
      });
    });

    describe('invalid state', () => {
      it('form group has correct props', () => {
        const propsWithError = {
          ...defaultProps,
          duplicateExceptionRegexError: 'some error string',
        };

        mountComponent(propsWithError);

        expect(findInputGroup().attributes()).toMatchObject({
          'invalid-feedback': propsWithError.duplicateExceptionRegexError,
        });
      });
    });
  });

  describe('when the duplicates are enabled', () => {
    it('has the correct toggle label', () => {
      mountComponent({ ...defaultProps, duplicatesAllowed: true });

      expect(findToggleLabel().exists()).toBe(true);
      expect(findToggleLabel().text()).toMatchInterpolatedText(DUPLICATES_ALLOWED_ENABLED);
    });

    it('hides the form input group', () => {
      mountComponent({ ...defaultProps, duplicatesAllowed: true });

      expect(findInputGroup().exists()).toBe(false);
    });
  });
});
