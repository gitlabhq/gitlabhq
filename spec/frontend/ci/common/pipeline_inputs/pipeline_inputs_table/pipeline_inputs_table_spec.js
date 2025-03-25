import { GlIcon, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table/pipeline_inputs_table.vue';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/pipeline_inputs_table/dynamic_value_renderer.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';

describe('PipelineInputsTable', () => {
  let wrapper;

  const defaultProps = {
    inputs: [
      {
        name: 'input1',
        description: 'This is a **markdown** description',
        type: '',
        default: 'value1',
        required: true,
      },
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
  const findDescriptionCells = () => wrapper.findAllByTestId('input-description-cell');
  const findDynamicValueRenderer = () => wrapper.findComponent(DynamicValueRenderer);
  const findDynamicValueRenderers = () => wrapper.findAllComponents(DynamicValueRenderer);
  const findRows = () => wrapper.findAllByTestId('input-row');
  const findRequiredAsterisk = () => wrapper.findByTestId('required-asterisk');
  const findMarkdown = () => wrapper.findComponent(Markdown);

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders a table row for each input', () => {
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

  describe('description column', () => {
    it('renders markdown when description exists', () => {
      createComponent();

      expect(findMarkdown().exists()).toBe(true);
      expect(findMarkdown().props('markdown')).toBe('This is a **markdown** description');
    });

    it('renders a dash when description is empty', () => {
      createComponent();

      // The second input in defaultProps has an empty description
      expect(findDescriptionCells().at(1).findComponent(GlIcon).exists()).toBe(true);
    });
  });

  describe('value column', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a DynamicValueRenderer for each input', () => {
      const dynamicValueRenderers = findDynamicValueRenderers();
      expect(dynamicValueRenderers).toHaveLength(defaultProps.inputs.length);

      defaultProps.inputs.forEach((input, index) => {
        expect(dynamicValueRenderers.at(index).props('item')).toEqual(input);
      });
    });
  });

  describe('event handling', () => {
    it('processes change and emits update event when a DynamicValueRenderer emits an update', async () => {
      createComponent();
      const updatedItem = defaultProps.inputs[0];
      const newValue = 'new value';
      await findDynamicValueRenderer().vm.$emit('update', {
        item: updatedItem,
        value: newValue,
      });

      expect(wrapper.emitted().update).toHaveLength(1);
      expect(wrapper.emitted().update[0][0]).toEqual({
        ...updatedItem,
        default: newValue,
      });
    });
  });
});
