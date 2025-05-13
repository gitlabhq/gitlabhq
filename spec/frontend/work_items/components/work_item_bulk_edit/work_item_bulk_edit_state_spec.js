import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WorkItemBulkEditState from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_state.vue';

describe('WorkItemBulkEditState component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(WorkItemBulkEditState, {
      propsData: {
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
    it('renders all states', () => {
      createComponent();

      expect(findListbox().props('items')).toEqual([
        { text: 'Open', value: 'reopen' },
        { text: 'Closed', value: 'close' },
      ]);
    });
  });

  describe('listbox text', () => {
    describe('with no selected state', () => {
      it('renders "Select state"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select state');
      });
    });

    describe('with selected state', () => {
      it.each`
        value       | text
        ${'reopen'} | ${'Open'}
        ${'close'}  | ${'Closed'}
      `('renders $text when state=$state', ({ value, text }) => {
        createComponent({ value });

        expect(findListbox().props('toggleText')).toBe(text);
      });
    });
  });
});
