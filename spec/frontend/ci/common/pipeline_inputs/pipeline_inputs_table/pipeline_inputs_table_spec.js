import { GlIcon, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table/pipeline_inputs_table.vue';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/pipeline_inputs_table/value_column/dynamic_value_renderer.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';

describe('PipelineInputsTable', () => {
  let wrapper;

  const defaultProps = {
    inputs: [
      {
        name: 'input1',
        description: 'This is a **markdown** description',
        type: '',
        value: 'value1',
        required: true,
        isSelected: true,
      },
      { name: 'input2', description: '', type: '', value: 'value2', isSelected: true },
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
  const findHelpIcon = () => wrapper.findComponent(HelpIcon);
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

  describe('selected inputs', () => {
    it('only renders rows for selected inputs', () => {
      createComponent({
        props: {
          inputs: [
            { name: 'input1', description: '', type: '', value: 'value1', isSelected: true },
            { name: 'input2', description: '', type: '', value: 'value2', isSelected: false },
          ],
        },
      });
      expect(findRows()).toHaveLength(1);
      expect(findRows().at(0).text()).toContain('input1');
      expect(findRows().at(0).text()).not.toContain('input2');
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

  describe('type column', () => {
    it('renders an info icon if the type is ARRAY', () => {
      createComponent({
        props: {
          inputs: [{ name: 'input1', description: '', type: 'ARRAY', value: [], isSelected: true }],
        },
      });

      expect(findHelpIcon().exists()).toBe(true);
      expect(findHelpIcon().attributes('title')).toBe('Array values must be in JSON format.');
    });

    it('does not render an info icon if the type is not ARRAY', () => {
      createComponent({
        props: {
          inputs: [{ name: 'input1', description: '', type: 'STRING', value: 'value1' }],
        },
      });

      expect(findHelpIcon().exists()).toBe(false);
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
        value: newValue,
      });
    });
  });
});
