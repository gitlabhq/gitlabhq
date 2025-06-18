import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineInputsPreviewDrawer from '~/ci/common/pipeline_inputs/pipeline_inputs_preview_drawer.vue';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

describe('PipelineInputsPreviewDrawer', () => {
  let wrapper;

  const defaultProps = {
    open: false,
    inputs: [],
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PipelineInputsPreviewDrawer, {
      propsData: { ...defaultProps, ...props },
      stubs: { GlDrawer },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findCodeBlock = () => wrapper.findByTestId('inputs-code-block');
  const findCodeLines = () => wrapper.findAllByTestId('inputs-code-line');

  describe('mounted', () => {
    beforeEach(() => {
      createComponent({ open: true });
    });

    it('renders drawer with correct props', () => {
      const drawer = findDrawer();

      expect(drawer.props()).toMatchObject({
        open: true,
        zIndex: DRAWER_Z_INDEX,
      });
    });

    it('displays correct title', () => {
      expect(wrapper.text()).toContain('Preview your inputs');
    });

    it('displays correct description', () => {
      expect(wrapper.text()).toContain('The pipeline will run with these inputs:');
    });

    it('renders code block container', () => {
      expect(findCodeBlock().exists()).toBe(true);
    });

    it('emits close event when drawer closes', async () => {
      await findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });

  describe('input formatting', () => {
    describe('with unchanged inputs', () => {
      beforeEach(() => {
        createComponent({
          open: true,
          inputs: [
            {
              name: 'environment',
              value: 'production',
              default: 'production',
              type: 'STRING',
              description: 'Target environment',
            },
          ],
        });
      });

      it('displays input without diff styling', () => {
        const line = (at) => findCodeLines().at(at);

        expect(line(0).text()).toBe('environment:');
        expect(line(1).text()).toBe('value: "production"');
        expect(line(2).text()).toBe('type: "STRING"');
        expect(line(3).text()).toBe('description: "Target environment"');
      });

      it('does not apply diff colors to unchanged values', () => {
        const valueLine = findCodeLines().wrappers.find((line) =>
          line.text().includes('value: "production"'),
        );

        expect(valueLine.classes()).not.toContain('gl-text-danger');
        expect(valueLine.classes()).not.toContain('gl-text-success');
      });
    });

    describe('with changed inputs', () => {
      beforeEach(() => {
        createComponent({
          open: true,
          inputs: [
            {
              name: 'environment',
              value: 'staging',
              default: 'production',
              type: 'STRING',
              description: 'Target environment',
            },
          ],
        });
      });

      it('displays input with diff styling', () => {
        const line = (at) => findCodeLines().at(at);

        expect(line(0).text()).toBe('environment:');
        expect(line(1).text()).toBe('-   value: "production"');
        expect(line(2).text()).toBe('+   value: "staging"');
        expect(line(3).text()).toBe('type: "STRING"');
        expect(line(4).text()).toBe('description: "Target environment"');
      });

      it('applies correct diff colors', () => {
        const removedLine = findCodeLines().wrappers.find((line) =>
          line.text().includes('-   value: "production"'),
        );
        const addedLine = findCodeLines().wrappers.find((line) =>
          line.text().includes('+   value: "staging"'),
        );

        expect(removedLine.classes()).toContain('gl-text-danger');
        expect(addedLine.classes()).toContain('gl-text-success');
      });
    });

    describe('with minimal input data', () => {
      beforeEach(() => {
        createComponent({
          open: true,
          inputs: [
            {
              name: 'simple',
              value: 'test',
              default: 'test',
            },
          ],
        });
      });

      it('handles inputs without type or description', () => {
        const line = (at) => findCodeLines().at(at);
        const lineTexts = findCodeLines().wrappers.map((item) => item.text());

        expect(line(0).text()).toBe('simple:');
        expect(line(1).text()).toBe('value: "test"');
        expect(lineTexts.filter((text) => text.includes('type:'))).toHaveLength(0);
        expect(lineTexts.filter((text) => text.includes('description:'))).toHaveLength(0);
      });
    });
  });

  describe('value type formatting', () => {
    describe.each([
      {
        name: 'string values',
        inputName: 'string_input',
        value: 'hello world',
        default: 'default_string',
        type: 'STRING',
        expectedValue: '"hello world"',
        expectedDefault: '"default_string"',
      },
      {
        name: 'number values',
        inputName: 'number_input',
        value: 42,
        default: 0,
        type: 'NUMBER',
        expectedValue: '42',
        expectedDefault: '0',
      },
      {
        name: 'boolean values',
        inputName: 'boolean_input',
        value: true,
        default: false,
        type: 'BOOLEAN',
        expectedValue: 'true',
        expectedDefault: 'false',
      },
      {
        name: 'object values',
        inputName: 'object_input',
        value: { key: 'value', count: 42 },
        default: { key: 'default' },
        type: 'OBJECT',
        expectedValue: '{"key":"value","count":42}',
        expectedDefault: '{"key":"default"}',
      },
      {
        name: 'array values',
        inputName: 'array_input',
        value: ['item1', 'item2', 42],
        default: [],
        type: 'ARRAY',
        expectedValue: '["item1","item2",42]',
        expectedDefault: '[]',
      },
      {
        name: 'empty string values',
        inputName: 'empty_string',
        value: '',
        default: 'not_empty',
        type: 'STRING',
        expectedValue: '""',
        expectedDefault: '"not_empty"',
      },
      {
        name: 'null values',
        inputName: 'null_input',
        value: 'actual_value',
        default: null,
        type: 'STRING',
        expectedValue: '"actual_value"',
        expectedDefault: 'null',
      },
    ])(
      '$name',
      ({ inputName, value, default: defaultValue, type, expectedValue, expectedDefault }) => {
        beforeEach(() => {
          createComponent({
            open: true,
            inputs: [
              {
                name: inputName,
                value,
                default: defaultValue,
                type,
              },
            ],
          });
        });

        it('formats values correctly with diff styling', () => {
          const line = (at) => findCodeLines().at(at);

          expect(line(0).text()).toBe(`${inputName}:`);
          expect(line(1).text()).toBe(`-   value: ${expectedDefault}`);
          expect(line(2).text()).toBe(`+   value: ${expectedValue}`);
          expect(line(3).text()).toBe(`type: "${type}"`);
        });
      },
    );
  });
});
