import { mount, shallowMount } from '@vue/test-utils';

import projectFeatureSetting from '~/pages/projects/shared/permissions/components/project_feature_setting.vue';
import projectFeatureToggle from '~/vue_shared/components/toggle_button.vue';

describe('Project Feature Settings', () => {
  const defaultProps = {
    name: 'Test',
    options: [[1, 1], [2, 2], [3, 3], [4, 4], [5, 5]],
    value: 1,
    disabledInput: false,
  };
  let wrapper;

  const mountComponent = customProps => {
    const propsData = { ...defaultProps, ...customProps };
    return shallowMount(projectFeatureSetting, { propsData });
  };

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Hidden name input', () => {
    it('should set the hidden name input if the name exists', () => {
      expect(wrapper.find(`input[name=${defaultProps.name}]`).attributes().value).toBe('1');
    });

    it('should not set the hidden name input if the name does not exist', () => {
      wrapper.setProps({ name: null });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(`input[name=${defaultProps.name}]`).exists()).toBe(false);
      });
    });
  });

  describe('Feature toggle', () => {
    it('should enable the feature toggle if the value is not 0', () => {
      expect(wrapper.find(projectFeatureToggle).props().value).toBe(true);
    });

    it('should enable the feature toggle if the value is less than 0', () => {
      wrapper.setProps({ value: -1 });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(projectFeatureToggle).props().value).toBe(true);
      });
    });

    it('should disable the feature toggle if the value is 0', () => {
      wrapper.setProps({ value: 0 });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(projectFeatureToggle).props().value).toBe(false);
      });
    });

    it('should disable the feature toggle if disabledInput is set', () => {
      wrapper.setProps({ disabledInput: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(projectFeatureToggle).props().disabledInput).toBe(true);
      });
    });

    it('should emit a change event when the feature toggle changes', () => {
      // Needs to be fully mounted to be able to trigger the click event on the internal button
      wrapper = mount(projectFeatureSetting, { propsData: defaultProps });

      expect(wrapper.emitted().change).toBeUndefined();
      wrapper
        .find(projectFeatureToggle)
        .find('button')
        .trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().change.length).toBe(1);
        expect(wrapper.emitted().change[0]).toEqual([0]);
      });
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
        wrapper.setProps({ disabledInput, value, options });

        return wrapper.vm.$nextTick(() => {
          if (isDisabled) {
            expect(wrapper.find('select').attributes().disabled).toEqual('disabled');
          } else {
            expect(wrapper.find('select').attributes().disabled).toBeUndefined();
          }
        });
      },
    );

    it('should emit the change when a new option is selected', () => {
      expect(wrapper.emitted().change).toBeUndefined();
      wrapper
        .findAll('option')
        .at(1)
        .trigger('change');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().change.length).toBe(1);
        expect(wrapper.emitted().change[0]).toEqual([2]);
      });
    });
  });
});
