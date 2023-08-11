import { shallowMount } from '@vue/test-utils';
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';

describe('ListboxInput', () => {
  let wrapper;

  // Props
  const label = 'label';
  const description = 'description';
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
  const id = 'id';

  // Finders
  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findGlListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.find('input');

  const createComponent = (propsData) => {
    wrapper = shallowMount(ListboxInput, {
      propsData: {
        label,
        description,
        name,
        defaultToggleText,
        items,
        ...propsData,
      },
      attrs: {
        id,
      },
    });
  };

  describe('wrapper', () => {
    it.each`
      description          | labelProp      | descriptionProp      | rendersGlFormGroup
      ${'does not render'} | ${''}          | ${''}                | ${false}
      ${'renders'}         | ${'labelProp'} | ${''}                | ${true}
      ${'renders'}         | ${''}          | ${'descriptionProp'} | ${true}
      ${'renders'}         | ${'labelProp'} | ${'descriptionProp'} | ${true}
    `(
      "$description a GlFormGroup when label is '$labelProp' and description is '$descriptionProp'",
      ({ labelProp, descriptionProp, rendersGlFormGroup }) => {
        createComponent({ label: labelProp, description: descriptionProp });

        expect(findGlFormGroup().exists()).toBe(rendersGlFormGroup);
      },
    );
  });

  describe('options', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes the label to the form group', () => {
      expect(findGlFormGroup().attributes('label')).toBe(label);
    });

    it('passes the description to the form group', () => {
      expect(findGlFormGroup().attributes('description')).toBe(description);
    });

    it('sets the input name', () => {
      expect(findInput().attributes('name')).toBe(name);
    });

    it('is not filterable with few items', () => {
      expect(findGlListbox().props('searchable')).toBe(false);
    });

    it('passes attributes to the root element', () => {
      expect(findGlFormGroup().attributes('id')).toBe(id);
    });
  });

  describe('props', () => {
    it.each([true, false])("passes %s to the listbox's fluidWidth prop", (fluidWidth) => {
      createComponent({ fluidWidth });

      expect(findGlListbox().props('fluidWidth')).toBe(fluidWidth);
    });

    it.each(['class-a class-b', ['class-a', 'class-b'], { 'class-a': true, 'class-b': true }])(
      'passes %s class to listbox',
      (toggleClass) => {
        createComponent({ toggleClass });

        expect(findGlListbox().props('toggleClass')).toBe(toggleClass);
      },
    );

    it.each(['right', 'left'])("passes %s to the listbox's placement prop", (placement) => {
      createComponent({ placement });

      expect(findGlListbox().props('placement')).toBe(placement);
    });

    it.each([true, false])("passes %s to the listbox's block prop", (block) => {
      createComponent({ block });

      expect(findGlListbox().props('block')).toBe(block);
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
    it('is searchable when there are more than 10 items', () => {
      createComponent({
        items: [
          {
            text: 'Group 1',
            options: [...Array(10).keys()].map((index) => ({
              text: index + 1,
              value: String(index + 1),
            })),
          },
          {
            text: 'Group 2',
            options: [{ text: 'Item 11', value: '11' }],
          },
        ],
      });

      expect(findGlListbox().props('searchable')).toBe(true);
    });

    it('passes all items to GlCollapsibleListbox by default', () => {
      createComponent();

      expect(findGlListbox().props('items')).toStrictEqual(items);
    });

    describe('with groups', () => {
      beforeEach(() => {
        createComponent();
        findGlListbox().vm.$emit('search', '1');
      });

      it('passes only the items that match the search string', () => {
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

      it('passes only the items that match the search string', () => {
        expect(findGlListbox().props('items')).toStrictEqual([{ text: 'Item 1', value: '1' }]);
      });
    });
  });
});
