import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table.vue';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/dynamic_value_renderer.vue';

describe('PipelineInputsTable', () => {
  let wrapper;

  const defaultProps = {
    inputs: [
      { name: 'input1', description: '', type: '', default: 'value1', required: true },
      { name: 'input2', description: '', type: '', default: 'value2' },
    ],
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(PipelineInputsTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findDynamicValueRenderer = () => wrapper.findComponent(DynamicValueRenderer);
  const findRows = () => wrapper.findAllByTestId('input-row');
  const findValueColumn = () => wrapper.findByTestId('input-values-th');
  const findRequiredAsterisk = () => wrapper.findByTestId('required-asterisk');

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders a table row for each message', () => {
      expect(findRows()).toHaveLength(defaultProps.inputs.length);
    });
  });

  describe('name column', () => {
    it('shows a red asterisk for required inputs', () => {
      createComponent();

      expect(findRequiredAsterisk().exists()).toBe(true);
      expect(findRequiredAsterisk().text()).toBe('*');
      expect(findRequiredAsterisk().classes()).toContain('gl-text-danger');
    });
  });

  describe('value column', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the "value" column', () => {
      expect(findValueColumn().exists()).toBe(true);
    });

    it('passes the item to DynamicValueRenderer', () => {
      const dynamicValueRenderer = findDynamicValueRenderer();
      expect(dynamicValueRenderer.props('item')).toEqual(defaultProps.inputs[0]);
    });
  });

  describe('event handling', () => {
    it('emits update event when a DynamicValueRenderer emits an update', async () => {
      createComponent();
      const updatedItem = defaultProps.inputs[0];
      const newValue = 'new value';
      await findDynamicValueRenderer().vm.$emit('update', { item: updatedItem, value: newValue });

      expect(wrapper.emitted().update).toHaveLength(1);
      expect(wrapper.emitted().update[0][0]).toEqual({
        ...updatedItem,
        value: newValue,
      });
    });
  });
});
