import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/pipeline_inputs_table/dynamic_value_renderer.vue';

describe('DynamicValueRenderer', () => {
  let wrapper;

  const defaultProps = {
    item: { name: 'input1', description: '', type: 'STRING', default: 'value1' },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DynamicValueRenderer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFormInput,
        GlFormTextarea,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findValidationFeedback = () => wrapper.findByTestId('validation-feedback');

  const getInputType = (type, hasOptions) => {
    if (hasOptions || type === 'BOOLEAN') return 'dropdown';
    if (type === 'ARRAY') return 'textarea';
    return 'input';
  };

  const setInputValue = async (value) => {
    await findInput().setValue(value);

    await nextTick();
  };

  describe('rendering', () => {
    describe('basic input types', () => {
      it('renders text input for string type', () => {
        createComponent();
        expect(findInput().exists()).toBe(true);
        expect(findInput().attributes('type')).toBe('text');
      });

      it('renders text input for number type', () => {
        createComponent({ props: { item: { ...defaultProps.item, type: 'NUMBER' } } });
        expect(findInput().exists()).toBe(true);
        expect(findInput().attributes('type')).toBe('text');
      });

      it('renders dropdown for boolean type', () => {
        createComponent({ props: { item: { ...defaultProps.item, type: 'BOOLEAN' } } });
        expect(findDropdown().exists()).toBe(true);
        expect(findInput().exists()).toBe(false);
      });

      it('renders dropdown when options are provided', () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              options: ['option1', 'option2'],
            },
          },
        });
        expect(findDropdown().exists()).toBe(true);
        expect(findInput().exists()).toBe(false);
      });
    });

    describe('array type handling', () => {
      it('renders a textarea for array inputs', () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              type: 'ARRAY',
            },
          },
        });

        expect(findTextarea().exists()).toBe(true);
        expect(findInput().exists()).toBe(false);
      });

      it('renders dropdown for array type when options are provided', () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              type: 'ARRAY',
              default: ['option1'],
              options: ['option1', 'option2', 'option3'],
            },
          },
        });

        expect(findDropdown().exists()).toBe(true);
        expect(findInput().exists()).toBe(false);

        const dropdownItems = findDropdown().props('items');
        expect(dropdownItems).toHaveLength(3);
        expect(dropdownItems[0].value).toBe('option1');
        expect(dropdownItems[1].value).toBe('option2');
        expect(dropdownItems[2].value).toBe('option3');
      });
    });
  });

  describe('event handling', () => {
    describe('basic input events', () => {
      it('emits update event when input value changes', async () => {
        createComponent();
        await findInput().vm.$emit('input', 'new value');

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0]).toEqual({
          item: defaultProps.item,
          value: 'new value',
        });
      });

      it('emits update event when dropdown value changes', async () => {
        createComponent({
          props: { item: { ...defaultProps.item, type: 'BOOLEAN' } },
        });
        await findDropdown().vm.$emit('select', 'true');

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0]).toEqual({
          item: { ...defaultProps.item, type: 'BOOLEAN' },
          value: true,
        });
      });
    });
  });

  describe('type conversion', () => {
    describe('convertToDisplayValue', () => {
      it.each`
        type         | value              | expectedDisplayValue | usesDropdown
        ${'STRING'}  | ${'test'}          | ${'test'}            | ${false}
        ${'NUMBER'}  | ${42}              | ${42}                | ${false}
        ${'BOOLEAN'} | ${true}            | ${'true'}            | ${true}
        ${'BOOLEAN'} | ${false}           | ${'false'}           | ${true}
        ${'ARRAY'}   | ${['a', 'b', 'c']} | ${'["a","b","c"]'}   | ${false}
      `(
        'converts $type value "$value" to display value "$expectedDisplayValue"',
        ({ type, value, expectedDisplayValue, usesDropdown }) => {
          createComponent({
            props: { item: { ...defaultProps.item, type, default: value } },
          });

          const inputType = getInputType(type, usesDropdown);

          switch (inputType) {
            case 'dropdown':
              expect(findDropdown().props('selected')).toBe(expectedDisplayValue);
              break;
            case 'textarea':
              expect(findTextarea().props('value')).toBe(expectedDisplayValue);
              break;
            default:
              expect(findInput().props('value')).toBe(expectedDisplayValue);
          }
        },
      );
    });

    describe('convertToType', () => {
      it.each`
        type         | inputValue | expectedTypedValue | usesDropdown
        ${'STRING'}  | ${'test'}  | ${'test'}          | ${false}
        ${'NUMBER'}  | ${'42'}    | ${42}              | ${false}
        ${'BOOLEAN'} | ${'true'}  | ${true}            | ${true}
        ${'BOOLEAN'} | ${'false'} | ${false}           | ${true}
        ${'ARRAY'}   | ${'a,b,c'} | ${'a,b,c'}         | ${false}
      `(
        'handles input value "$inputValue" for $type type appropriately',
        async ({ type, inputValue, expectedTypedValue, usesDropdown }) => {
          createComponent({
            props: { item: { ...defaultProps.item, type } },
          });

          const inputType = getInputType(type, usesDropdown);

          switch (inputType) {
            case 'dropdown':
              await findDropdown().vm.$emit('select', inputValue);
              break;
            case 'textarea':
              await findTextarea().vm.$emit('input', inputValue);
              break;
            default:
              await findInput().vm.$emit('input', inputValue);
          }

          expect(wrapper.emitted('update')[0][0].value).toEqual(expectedTypedValue);
        },
      );
    });
  });

  describe('validation', () => {
    describe('attributes', () => {
      it.each`
        description                     | itemProps              | attribute            | expectedValue
        ${'regex pattern attribute'}    | ${{ regex: '[a-z]+' }} | ${'pattern'}         | ${'[a-z]+'}
        ${'number type data attribute'} | ${{ type: 'NUMBER' }}  | ${'data-field-type'} | ${'NUMBER'}
        ${'json array data attribute'}  | ${{ type: 'ARRAY' }}   | ${'data-json-array'} | ${'true'}
      `('applies $description to input', ({ itemProps, attribute, expectedValue }) => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              ...itemProps,
            },
          },
        });

        const inputComponent = itemProps.type === 'ARRAY' ? findTextarea() : findInput();
        expect(inputComponent.attributes(attribute)).toBe(expectedValue);
      });

      // Separate test for required attribute because vue 2 and vue 3 handle required differently
      it('applies required attribute to input', () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              required: true,
            },
          },
        });
        expect(findInput().element.hasAttribute('required')).toBe(true);
      });
    });

    describe('invalid text feedback', () => {
      it('displays validation feedback when required field is empty', async () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              required: true,
            },
          },
        });

        await setInputValue('');

        expect(findValidationFeedback().exists()).toBe(true);
        expect(findValidationFeedback().text()).toContain('This is required and must be defined.');
      });

      it('displays validation feedback for non-numeric value in number field', async () => {
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              type: 'NUMBER',
            },
          },
        });

        await setInputValue('not-a-number');

        expect(findValidationFeedback().exists()).toBe(true);
        expect(findValidationFeedback().text()).toContain('The value must contain only numbers.');
      });

      it('includes pattern information in validation feedback for regex errors', async () => {
        const regex = '[a-z]+';
        createComponent({
          props: {
            item: {
              ...defaultProps.item,
              regex,
            },
          },
        });

        await setInputValue('123');

        expect(findValidationFeedback().exists()).toBe(true);
        expect(findValidationFeedback().text()).toContain(
          'The value must match the defined regular expression.',
        );
        expect(findValidationFeedback().text()).toContain(`Pattern: ${regex}`);
      });
    });
  });
});
