import { GlSprintf, GlToggle, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/settings/group/components/maven_settings.vue';

import {
  MAVEN_TITLE,
  MAVEN_SETTINGS_SUBTITLE,
  MAVEN_DUPLICATES_ALLOWED_DISABLED,
  MAVEN_DUPLICATES_ALLOWED_ENABLED,
  MAVEN_SETTING_EXCEPTION_TITLE,
  MAVEN_SETTINGS_EXCEPTION_LEGEND,
} from '~/packages_and_registries/settings/group/constants';

describe('Maven Settings', () => {
  let wrapper;

  const defaultProps = {
    mavenDuplicatesAllowed: false,
    mavenDuplicateExceptionRegex: 'foo',
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
    wrapper = null;
  });

  const findTitle = () => wrapper.find('h5');
  const findSubTitle = () => wrapper.find('p');
  const findToggle = () => wrapper.find(GlToggle);
  const findToggleLabel = () => wrapper.find('[data-testid="toggle-label"');

  const findInputGroup = () => wrapper.find(GlFormGroup);
  const findInput = () => wrapper.find(GlFormInput);

  it('has a title', () => {
    mountComponent();

    expect(findTitle().exists()).toBe(true);
    expect(findTitle().text()).toBe(MAVEN_TITLE);
  });

  it('has a subtitle', () => {
    mountComponent();

    expect(findSubTitle().exists()).toBe(true);
    expect(findSubTitle().text()).toBe(MAVEN_SETTINGS_SUBTITLE);
  });

  it('has a toggle', () => {
    mountComponent();

    expect(findToggle().exists()).toBe(true);
    expect(findToggle().props()).toMatchObject({
      label: component.i18n.MAVEN_TOGGLE_LABEL,
      value: defaultProps.mavenDuplicatesAllowed,
    });
  });

  it('toggle emits an update event', () => {
    mountComponent();

    findToggle().vm.$emit('change', false);

    expect(wrapper.emitted('update')).toEqual([[{ mavenDuplicatesAllowed: false }]]);
  });

  describe('when the duplicates are disabled', () => {
    it('the toggle has the disabled message', () => {
      mountComponent();

      expect(findToggleLabel().exists()).toBe(true);
      expect(findToggleLabel().text()).toMatchInterpolatedText(MAVEN_DUPLICATES_ALLOWED_DISABLED);
    });

    it('shows a form group with an input field', () => {
      mountComponent();

      expect(findInputGroup().exists()).toBe(true);

      expect(findInputGroup().attributes()).toMatchObject({
        'label-for': 'maven-duplicated-settings-regex-input',
        label: MAVEN_SETTING_EXCEPTION_TITLE,
        description: MAVEN_SETTINGS_EXCEPTION_LEGEND,
      });
    });

    it('shows an input field', () => {
      mountComponent();

      expect(findInput().exists()).toBe(true);

      expect(findInput().attributes()).toMatchObject({
        id: 'maven-duplicated-settings-regex-input',
        value: defaultProps.mavenDuplicateExceptionRegex,
      });
    });

    it('input change event emits an update event', () => {
      mountComponent();

      findInput().vm.$emit('change', 'bar');

      expect(wrapper.emitted('update')).toEqual([[{ mavenDuplicateExceptionRegex: 'bar' }]]);
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
          mavenDuplicateExceptionRegexError: 'some error string',
        };

        mountComponent(propsWithError);

        expect(findInputGroup().attributes()).toMatchObject({
          'invalid-feedback': propsWithError.mavenDuplicateExceptionRegexError,
        });
      });
    });
  });

  describe('when the duplicates are enabled', () => {
    it('has the correct toggle label', () => {
      mountComponent({ ...defaultProps, mavenDuplicatesAllowed: true });

      expect(findToggleLabel().exists()).toBe(true);
      expect(findToggleLabel().text()).toMatchInterpolatedText(MAVEN_DUPLICATES_ALLOWED_ENABLED);
    });

    it('hides the form input group', () => {
      mountComponent({ ...defaultProps, mavenDuplicatesAllowed: true });

      expect(findInputGroup().exists()).toBe(false);
    });
  });
});
