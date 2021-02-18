import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ProjectFeatureSetting from '~/pages/projects/shared/permissions/components/project_feature_setting.vue';

describe('Project Feature Settings', () => {
  const defaultProps = {
    name: 'Test',
    options: [
      [1, 1],
      [2, 2],
      [3, 3],
      [4, 4],
      [5, 5],
    ],
    value: 1,
    disabledInput: false,
    showToggle: true,
  };
  let wrapper;

  const findHiddenInput = () => wrapper.find(`input[name=${defaultProps.name}]`);
  const findToggle = () => wrapper.findComponent(GlToggle);

  const mountComponent = (customProps = {}) =>
    shallowMount(ProjectFeatureSetting, {
      propsData: {
        ...defaultProps,
        ...customProps,
      },
    });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Hidden name input', () => {
    it('should set the hidden name input if the name exists', () => {
      wrapper = mountComponent();

      expect(findHiddenInput().attributes('value')).toBe('1');
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

    it('should enable the feature toggle if the value is not 0', () => {
      wrapper = mountComponent();

      expect(findToggle().props('value')).toBe(true);
    });

    it('should enable the feature toggle if the value is less than 0', () => {
      wrapper = mountComponent({ value: -1 });

      expect(findToggle().props('value')).toBe(true);
    });

    it('should disable the feature toggle if the value is 0', () => {
      wrapper = mountComponent({ value: 0 });

      expect(findToggle().props('value')).toBe(false);
    });

    it('should disable the feature toggle if disabledInput is set', () => {
      wrapper = mountComponent({ disabledInput: true });

      expect(findToggle().props('disabled')).toBe(true);
    });

    it('should emit a change event when the feature toggle changes', () => {
      wrapper = mountComponent({ propsData: defaultProps });

      expect(wrapper.emitted('change')).toBeUndefined();

      findToggle().vm.$emit('change', false);

      expect(wrapper.emitted('change')).toHaveLength(1);
      expect(wrapper.emitted('change')[0]).toEqual([0]);
    });
  });

  describe('Project repo select', () => {
    it.each`
      disabledInput | value | options                     | isDisabled
      ${true}       | ${0}  | ${[[1, 1]]}                 | ${true}
      ${true}       | ${1}  | ${[[1, 1], [2, 2], [3, 3]]} | ${true}
      ${false}      | ${0}  | ${[[1, 1], [2, 2], [3, 3]]} | ${true}
      ${false}      | ${1}  | ${[[1, 1]]}                 | ${true}
      ${false}      | ${1}  | ${[[1, 1], [2, 2], [3, 3]]} | ${false}
    `(
      'should set disabled to $isDisabled when disabledInput is $disabledInput, the value is $value and options are $options',
      ({ disabledInput, value, options, isDisabled }) => {
        wrapper = mountComponent({ disabledInput, value, options });

        const expected = isDisabled ? 'disabled' : undefined;

        expect(wrapper.find('select').attributes('disabled')).toBe(expected);
      },
    );

    it('should emit the change when a new option is selected', () => {
      wrapper = mountComponent();

      expect(wrapper.emitted('change')).toBeUndefined();

      wrapper.findAll('option').at(1).trigger('change');

      expect(wrapper.emitted('change')).toHaveLength(1);
      expect(wrapper.emitted('change')[0]).toEqual([2]);
    });
  });
});
