import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/dynamic_value_renderer.vue';

describe('DynamicValueRenderer', () => {
  let wrapper;

  const defaultProps = {
    item: { name: 'input1', description: '', type: 'STRING', default: 'value1', regex: '[a-z]+' },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DynamicValueRenderer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFormInput,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findInput = () => wrapper.findByTestId('value-input');
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findValidationFeedback = () => wrapper.findByTestId('validation-feedback');

  const setInputValue = async (value) => {
    await findInput().setValue(value);
    await findInput().trigger('blur');

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
      it('renders text input for array type and displays array as JSON string', () => {
        const arrayValue = ['item1', 'item2', 'item3'];
        createComponent({
          props: {
            item: { ...defaultProps.item, type: 'ARRAY', default: arrayValue },
          },
        });

        expect(findInput().exists()).toBe(true);
        expect(findInput().attributes('type')).toBe('text');
        expect(findInput().props('value')).toBe(JSON.stringify(arrayValue));
      });

      it('renders text input for array type with complex objects and displays as JSON string', () => {
        const complexArrayValue = [{ hello: '2' }, '4', '6'];
        createComponent({
          props: {
            item: { ...defaultProps.item, type: 'ARRAY', default: complexArrayValue },
          },
        });

        expect(findInput().exists()).toBe(true);
        expect(findInput().props('value')).toBe(JSON.stringify(complexArrayValue));
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

          if (usesDropdown) {
            expect(findDropdown().props('selected')).toBe(expectedDisplayValue);
          } else {
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

          if (usesDropdown) {
            await findDropdown().vm.$emit('select', inputValue);
          } else {
            await findInput().vm.$emit('input', inputValue);
          }

          expect(wrapper.emitted('update')[0][0].value).toEqual(expectedTypedValue);
        },
      );
    });
  });

  describe('validation', () => {
    it.each`
      description                     | itemProps              | attribute            | expectedValue
      ${'regex pattern attribute'}    | ${{ regex: '[a-z]+' }} | ${'pattern'}         | ${'[a-z]+'}
      ${'number type data attribute'} | ${{ type: 'NUMBER' }}  | ${'data-field-type'} | ${'NUMBER'}
    `('applies $description to input', ({ itemProps, attribute, expectedValue }) => {
      createComponent({
        props: {
          item: {
            ...defaultProps.item,
            ...itemProps,
          },
        },
      });

      expect(findInput().attributes(attribute)).toBe(expectedValue);
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
    it.each`
      name                                   | itemProps              | value             | expectedMessage
      ${'required field is empty'}           | ${{ required: true }}  | ${''}             | ${'This is mandatory and must be defined.'}
      ${'non-numeric value in number field'} | ${{ type: 'NUMBER' }}  | ${'not-a-number'} | ${'The value must contain only numbers.'}
      ${'pattern does not match'}            | ${{ regex: '[a-z]+' }} | ${'123'}          | ${'The value must match the defined regular expression.'}
    `('displays validation feedback when $name', async ({ itemProps, value, expectedMessage }) => {
      createComponent({
        props: {
          item: {
            ...defaultProps.item,
            ...itemProps,
          },
        },
      });

      await setInputValue(value);

      expect(findValidationFeedback().exists()).toBe(true);
      expect(findValidationFeedback().text()).toContain(expectedMessage);
    });

    it('shows tooltip with pattern information for regex validation errors', async () => {
      createComponent();

      await setInputValue('123');

      const validationFeedbackTooltipDirective = getBinding(
        findValidationFeedback().element,
        'gl-tooltip',
      );
      expect(validationFeedbackTooltipDirective.value).toBe(`Pattern: ${defaultProps.item.regex}`);
    });
  });
});
