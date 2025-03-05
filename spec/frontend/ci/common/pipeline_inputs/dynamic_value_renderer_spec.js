import { shallowMount } from '@vue/test-utils';
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import DynamicValueRenderer from '~/ci/common/pipeline_inputs/dynamic_value_renderer.vue';

describe('DynamicValueRenderer', () => {
  let wrapper;

  const defaultProps = {
    item: { name: 'input1', description: '', type: 'string', value: 'value1' },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(DynamicValueRenderer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findInput = () => wrapper.findComponent(GlFormInput);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('rendering', () => {
    describe('basic input types', () => {
      it('renders text input for string type', () => {
        createComponent();
        expect(findInput().exists()).toBe(true);
        expect(findInput().attributes('type')).toBe('text');
      });

      it('renders number input for number type', () => {
        createComponent({ props: { item: { ...defaultProps.item, type: 'number' } } });
        expect(findInput().exists()).toBe(true);
        expect(findInput().attributes('type')).toBe('number');
      });

      it('renders dropdown for boolean type', () => {
        createComponent({ props: { item: { ...defaultProps.item, type: 'boolean' } } });
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
            item: { ...defaultProps.item, type: 'array', value: arrayValue },
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
            item: { ...defaultProps.item, type: 'array', value: complexArrayValue },
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
              type: 'array',
              value: ['option1'],
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
          props: { item: { ...defaultProps.item, type: 'boolean' } },
        });
        await findDropdown().vm.$emit('select', 'true');

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0]).toEqual({
          item: { ...defaultProps.item, type: 'boolean' },
          value: 'true',
        });
      });
    });

    describe('array input events', () => {
      it('converts string input to array when type is array', async () => {
        createComponent({
          props: { item: { ...defaultProps.item, type: 'array', value: [] } },
        });

        await findInput().vm.$emit('input', 'a, b, c');

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0].value).toEqual(['a', 'b', 'c']);
      });

      it('handles JSON array input when type is array', async () => {
        createComponent({
          props: { item: { ...defaultProps.item, type: 'array', value: [] } },
        });

        await findInput().vm.$emit('input', '["item1", "item2"]');

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0].value).toEqual(['item1', 'item2']);
      });

      it('handles complex JSON array input with objects', async () => {
        createComponent({
          props: { item: { ...defaultProps.item, type: 'array', value: [] } },
        });

        const complexInput = '[{"hello":"2"}, "4", "6"]';
        await findInput().vm.$emit('input', complexInput);

        expect(wrapper.emitted().update).toHaveLength(1);
        expect(wrapper.emitted('update')[0][0].value).toEqual([{ hello: '2' }, '4', '6']);
      });
    });
  });
});
