import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemBulkEditDropdown from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_dropdown.vue';
import { BULK_EDIT_NO_VALUE } from '~/work_items/constants';

describe('WorkItemBulkEditDropdown component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(WorkItemBulkEditDropdown, {
      propsData: {
        headerText: 'Select state',
        items: [
          { text: 'Open', value: 'reopen' },
          { text: 'Closed', value: 'close' },
        ],
        label: 'State',
        ...props,
      },
      stubs: {
        GlFormGroup: true,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  it('renders the form group', () => {
    createComponent();

    expect(findFormGroup().attributes('label')).toBe('State');
  });

  it('renders a header and reset button', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      headerText: 'Select state',
      resetButtonLabel: 'Reset',
    });
  });

  it('emits "input" event when the listbox is reset', () => {
    createComponent();

    findListbox().vm.$emit('reset');

    expect(wrapper.emitted('input')).toEqual([[undefined]]);
  });

  describe('listbox items', () => {
    it('renders all items by default', () => {
      createComponent();

      expect(findListbox().props('items')).toEqual([
        { text: 'Open', value: 'reopen' },
        { text: 'Closed', value: 'close' },
      ]);
    });

    it('renders "No state" when noValueText is provided', () => {
      createComponent({ noValueText: 'No state' });

      expect(findListbox().props('items')).toEqual([
        {
          text: 'No state',
          textSrOnly: true,
          options: [{ text: 'No state', value: BULK_EDIT_NO_VALUE }],
        },
        {
          text: 'All',
          textSrOnly: true,
          options: [
            { text: 'Open', value: 'reopen' },
            { text: 'Closed', value: 'close' },
          ],
        },
      ]);
    });
  });

  describe('listbox text', () => {
    describe('with no selected value', () => {
      it('renders "Select state"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select state');
      });
    });

    describe('with selected value', () => {
      it.each`
        value       | text
        ${'reopen'} | ${'Open'}
        ${'close'}  | ${'Closed'}
      `('renders $text when value=$state', ({ value, text }) => {
        createComponent({ value });

        expect(findListbox().props('toggleText')).toBe(text);
      });
    });

    describe('with "No state"', () => {
      it('renders "No state"', () => {
        createComponent({ noValueText: 'No state', value: BULK_EDIT_NO_VALUE });

        expect(findListbox().props('toggleText')).toBe('No state');
      });
    });
  });
});
