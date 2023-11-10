import FindingsDrawerItem from '~/diffs/components/shared/findings_drawer_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

let wrapper;

const mockDescription = 'testDescription';
const slotTestId = 'findings-drawer-item-value-slot';
const mockValue = 'testValue';
const mockSlot = `<span data-testid="${slotTestId}">mockSlot</span>`;
const mockSlotText = 'mockSlot';

describe('FindingsDrawerItem', () => {
  const description = () => wrapper.findByTestId('findings-drawer-item-description');

  const valueSlot = () => wrapper.findByTestId(slotTestId);
  const valueProp = () => wrapper.findByTestId('findings-drawer-item-value-prop');

  const createWrapper = (props = {}, slots = {}) => {
    return shallowMountExtended(FindingsDrawerItem, {
      propsData: {
        ...props,
      },
      slots: {
        ...slots,
      },
    });
  };

  it('renders with default values', () => {
    wrapper = createWrapper();
    expect(description().text()).toContain('');
    expect(valueProp().text()).toContain('');
  });

  it('renders description and value props correctly', () => {
    wrapper = createWrapper({ description: mockDescription, value: mockValue });
    expect(description().text()).toContain(mockDescription);
    expect(valueProp().text()).toContain(mockValue);
  });

  describe('when slot content is passed', () => {
    it('renders slot content', () => {
      wrapper = createWrapper({}, { value: mockSlot });
      expect(valueSlot().text()).toContain(mockSlotText);
    });

    describe('when value prop is passed', () => {
      it('does not render value prop', () => {
        wrapper = createWrapper({ value: mockValue }, { value: mockSlot });
        expect(valueProp().exists()).toBe(false);
      });
    });
  });
});
