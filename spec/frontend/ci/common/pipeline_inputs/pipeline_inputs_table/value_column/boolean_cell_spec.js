import { GlButton, GlButtonGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BooleanCell from '~/ci/common/pipeline_inputs/pipeline_inputs_table/value_column/boolean_cell.vue';

describe('BooleanCell', () => {
  let wrapper;

  const defaultProps = {
    input: { name: 'boolInput', type: 'BOOLEAN', value: false },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(BooleanCell, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlButton,
        GlButtonGroup,
      },
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findTrueButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findFalseButton = () => wrapper.findAllComponents(GlButton).at(1);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a button group with two buttons', () => {
      expect(findButtonGroup().exists()).toBe(true);
      expect(findButtons()).toHaveLength(2);
    });

    it('renders true and false buttons', () => {
      expect(findTrueButton().text()).toBe('true');
      expect(findFalseButton().text()).toBe('false');
    });

    it('selects the button matching the value', () => {
      createComponent({
        props: {
          input: { ...defaultProps.input, value: true },
        },
      });

      expect(findTrueButton().props('selected')).toBe(true);
      expect(findFalseButton().props('selected')).toBe(false);
    });
  });

  describe('event handling', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits update event when value is updated', async () => {
      // First set to true (since current value is false)
      findTrueButton().vm.$emit('click');
      await waitForPromises();
      expect(wrapper.emitted('update')).toHaveLength(1);
      expect(wrapper.emitted('update')[0][0]).toEqual({
        input: defaultProps.input,
        value: true,
      });
    });

    it('does not emit event when clicking already selected button', async () => {
      // Current value is false, so clicking false button should not emit
      findFalseButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('update')).toBeUndefined();
    });
  });

  describe('value conversion', () => {
    it('converts undefined to "false"', () => {
      createComponent({
        props: {
          input: { ...defaultProps.input, value: undefined },
        },
      });
      expect(findFalseButton().props('selected')).toBe(true);
    });

    it('converts null to "false"', () => {
      createComponent({
        props: {
          input: { ...defaultProps.input, value: null },
        },
      });
      expect(findFalseButton().props('selected')).toBe(true);
    });

    it('converts boolean values to string values for display', () => {
      createComponent({
        props: {
          input: { ...defaultProps.input, value: true },
        },
      });

      expect(findTrueButton().props('selected')).toBe(true);
      expect(findFalseButton().props('selected')).toBe(false);
    });

    it('converts string values back to boolean values when emitting', async () => {
      createComponent();

      findTrueButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('update')[0][0].value).toBe(true);
      expect(typeof wrapper.emitted('update')[0][0].value).toBe('boolean');
    });
  });
});
