import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectFeatureSetting from '~/pages/projects/shared/permissions/components/project_feature_setting.vue';
import {
  featureAccessLevelNone,
  featureAccessLevelEveryone,
  featureAccessLevelMembers,
} from '~/pages/projects/shared/permissions/constants';

describe('Project Feature Settings', () => {
  const defaultOptions = [
    featureAccessLevelNone,
    featureAccessLevelMembers,
    featureAccessLevelEveryone,
  ];

  const defaultInitialValue = featureAccessLevelMembers.value;

  const defaultProps = {
    name: 'Test',
    options: defaultOptions,
    value: defaultInitialValue,
    disabledInput: false,
    showToggle: true,
  };

  let wrapper;

  const findHiddenInput = () => wrapper.find(`input[name=${defaultProps.name}]`);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findSelect = () => wrapper.find('select');

  const mountComponent = (customProps = {}) =>
    shallowMount(ProjectFeatureSetting, {
      propsData: {
        ...defaultProps,
        ...customProps,
      },
    });

  describe('Hidden name input', () => {
    it('should set the hidden name input if the name exists', () => {
      wrapper = mountComponent();

      expect(findHiddenInput().attributes('value')).toBe(defaultInitialValue.toString());
    });

    it('should not set the hidden name input if the name does not exist', () => {
      wrapper = mountComponent({ name: null });

      expect(findHiddenInput().exists()).toBe(false);
    });
  });

  describe('Feature toggle', () => {
    it('should be hidden if "showToggle" is passed false', () => {
      wrapper = mountComponent({ showToggle: false });

      expect(findToggle().exists()).toBe(false);
    });

    it('should enable the feature toggle if the value is not none', () => {
      wrapper = mountComponent({ value: featureAccessLevelMembers.value });

      expect(findToggle().props('value')).toBe(true);
    });

    it('should disable the feature toggle if the value is none', () => {
      wrapper = mountComponent({ value: featureAccessLevelNone.value });

      expect(findToggle().props('value')).toBe(false);
    });

    it('should disable the feature toggle if disabledInput is set', () => {
      wrapper = mountComponent({ disabledInput: true });

      expect(findToggle().props('disabled')).toBe(true);
    });

    it('should disable the access level dropdown if disabledSelectInput is set', () => {
      wrapper = mountComponent({ disabledSelectInput: true });

      expect(findSelect().attributes('disabled')).toBe('disabled');
    });

    it('should emit a change event when the feature toggle changes', () => {
      wrapper = mountComponent();

      expect(wrapper.emitted('change')).toBeUndefined();

      findToggle().vm.$emit('change', false);

      expect(wrapper.emitted('change')).toStrictEqual([[featureAccessLevelNone.value]]);
    });

    describe.each`
      description                                                     | emittedSource                | recentValue                         | options                                                    | emittedValue
      ${'when previously selected value is in available options'}     | ${'recently selected value'} | ${featureAccessLevelMembers.value}  | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${featureAccessLevelMembers.value}
      ${'when previously selected value is not in available options'} | ${'last option'}             | ${featureAccessLevelEveryone.value} | ${[featureAccessLevelMembers]}                             | ${featureAccessLevelMembers.value}
      ${'when previously selected value is none'}                     | ${'last option'}             | ${featureAccessLevelNone.value}     | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${featureAccessLevelEveryone.value}
      ${'when previously selected value is undefined'}                | ${'last option'}             | ${undefined}                        | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${featureAccessLevelEveryone.value}
    `(`$description`, ({ recentValue, options, emittedValue, emittedSource }) => {
      beforeEach(() => {
        wrapper = mountComponent({
          value: recentValue,
          options,
        });
      });

      describe('when toggle has been disabled and then re-enabled', () => {
        it(`emits the ${emittedSource}`, () => {
          findToggle().vm.$emit('change', false);
          findToggle().vm.$emit('change', true);

          expect(wrapper.emitted('change')).toStrictEqual([
            [featureAccessLevelNone.value],
            [emittedValue],
          ]);
        });
      });
    });
  });

  describe('Project repo select', () => {
    it.each`
      disabledSelectInput | disabledInput | value                              | options                                                    | isDisabled
      ${true}             | ${false}      | ${featureAccessLevelMembers.value} | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${true}
      ${false}            | ${true}       | ${featureAccessLevelNone.value}    | ${[featureAccessLevelMembers]}                             | ${true}
      ${false}            | ${true}       | ${featureAccessLevelMembers.value} | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${true}
      ${false}            | ${false}      | ${featureAccessLevelNone.value}    | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${true}
      ${false}            | ${false}      | ${featureAccessLevelMembers.value} | ${[featureAccessLevelMembers]}                             | ${true}
      ${false}            | ${false}      | ${featureAccessLevelMembers.value} | ${[featureAccessLevelMembers, featureAccessLevelEveryone]} | ${false}
    `(
      'should set disabled to $isDisabled when disabledSelectInput is $disabledSelectInput, disabledInput is $disabledInput, the value is $value and options are $options',
      ({ disabledSelectInput, disabledInput, value, options, isDisabled }) => {
        wrapper = mountComponent({ disabledSelectInput, disabledInput, value, options });

        const expected = isDisabled ? 'disabled' : undefined;

        expect(findSelect().attributes('disabled')).toBe(expected);
      },
    );

    it('should emit the change when a new option is selected', async () => {
      wrapper = mountComponent();

      expect(wrapper.emitted('change')).toBeUndefined();

      await wrapper
        .findAll('option')
        .at(defaultOptions.indexOf(featureAccessLevelEveryone))
        .setSelected();

      expect(wrapper.emitted('change')).toStrictEqual([[featureAccessLevelEveryone.value]]);
    });

    it('value of select matches prop `value` if options are modified', async () => {
      wrapper = mountComponent();

      await wrapper.setProps({
        value: featureAccessLevelNone.value,
        options: [featureAccessLevelNone],
      });
      expect(findSelect().element.selectedIndex).toBe(0);

      await wrapper.setProps({ value: featureAccessLevelEveryone.value, options: defaultOptions });
      expect(findSelect().element.selectedIndex).toBe(
        defaultOptions.indexOf(featureAccessLevelEveryone),
      );
    });
  });
});
