import { GlFormSelect } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import ItemState from '~/work_items/components/item_state.vue';

describe('ItemState', () => {
  let wrapper;

  const findLabel = () => wrapper.find('label').text();
  const findFormSelect = () => wrapper.findComponent(GlFormSelect);
  const selectedValue = () => wrapper.find('option:checked').element.value;

  const clickOpen = () => wrapper.findAll('option').at(0).setSelected();

  const createComponent = ({ state = STATE_OPEN, disabled = false } = {}) => {
    wrapper = mount(ItemState, {
      propsData: {
        state,
        disabled,
      },
    });
  };

  it('renders label and dropdown', () => {
    createComponent();

    expect(findLabel()).toBe('Status');
    expect(selectedValue()).toBe(STATE_OPEN);
  });

  it('renders dropdown for closed', () => {
    createComponent({ state: STATE_CLOSED });

    expect(selectedValue()).toBe(STATE_CLOSED);
  });

  it('emits changed event', async () => {
    createComponent({ state: STATE_CLOSED });

    await clickOpen();

    expect(wrapper.emitted('changed')).toEqual([[STATE_OPEN]]);
  });

  it('does not emits changed event if clicking selected value', async () => {
    createComponent({ state: STATE_OPEN });

    await clickOpen();

    expect(wrapper.emitted('changed')).toBeUndefined();
  });

  describe('form select disabled prop', () => {
    describe.each`
      description            | disabled | value
      ${'when not disabled'} | ${false} | ${undefined}
      ${'when disabled'}     | ${true}  | ${'disabled'}
    `('$description', ({ disabled, value }) => {
      it(`renders form select component with disabled=${value}`, () => {
        createComponent({ disabled });

        expect(findFormSelect().attributes('disabled')).toBe(value);
      });
    });
  });
});
