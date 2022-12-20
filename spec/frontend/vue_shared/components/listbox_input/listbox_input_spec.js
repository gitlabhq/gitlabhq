import { shallowMount } from '@vue/test-utils';
import { GlListbox } from '@gitlab/ui';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';

describe('ListboxInput', () => {
  let wrapper;

  // Props
  const name = 'name';
  const defaultToggleText = 'defaultToggleText';
  const items = [
    {
      text: 'Group 1',
      options: [
        { text: 'Item 1', value: '1' },
        { text: 'Item 2', value: '2' },
      ],
    },
    {
      text: 'Group 2',
      options: [{ text: 'Item 3', value: '3' }],
    },
  ];

  // Finders
  const findGlListbox = () => wrapper.findComponent(GlListbox);
  const findInput = () => wrapper.find('input');

  const createComponent = (propsData) => {
    wrapper = shallowMount(ListboxInput, {
      propsData: {
        name,
        defaultToggleText,
        items,
        ...propsData,
      },
    });
  };

  describe('input attributes', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets the input name', () => {
      expect(findInput().attributes('name')).toBe(name);
    });
  });

  describe('toggle text', () => {
    it('uses the default toggle text while no value is selected', () => {
      createComponent();

      expect(findGlListbox().props('toggleText')).toBe(defaultToggleText);
    });

    it("uses the selected option's text as the toggle text", () => {
      const selectedOption = items[0].options[0];
      createComponent({ selected: selectedOption.value });

      expect(findGlListbox().props('toggleText')).toBe(selectedOption.text);
    });
  });

  describe('input value', () => {
    const selectedOption = items[0].options[0];

    beforeEach(() => {
      createComponent({ selected: selectedOption.value });
      jest.spyOn(findInput().element, 'dispatchEvent');
    });

    it("sets the listbox's and input's values", () => {
      const { value } = selectedOption;

      expect(findGlListbox().props('selected')).toBe(value);
      expect(findInput().attributes('value')).toBe(value);
    });

    describe("when the listbox's value changes", () => {
      const newSelectedOption = items[1].options[0];

      beforeEach(() => {
        findGlListbox().vm.$emit('select', newSelectedOption.value);
      });

      it('emits the `select` event', () => {
        expect(wrapper.emitted('select')).toEqual([[newSelectedOption.value]]);
      });
    });
  });

  describe('search', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes all items to GlListbox by default', () => {
      createComponent();
      expect(findGlListbox().props('items')).toStrictEqual(items);
    });

    describe('with groups', () => {
      beforeEach(() => {
        createComponent();
        findGlListbox().vm.$emit('search', '1');
      });

      it('passes only the items that match the search string', async () => {
        expect(findGlListbox().props('items')).toStrictEqual([
          {
            text: 'Group 1',
            options: [{ text: 'Item 1', value: '1' }],
          },
        ]);
      });
    });

    describe('with flat items', () => {
      beforeEach(() => {
        createComponent({
          items: items[0].options,
        });
        findGlListbox().vm.$emit('search', '1');
      });

      it('passes only the items that match the search string', async () => {
        expect(findGlListbox().props('items')).toStrictEqual([{ text: 'Item 1', value: '1' }]);
      });
    });
  });
});
