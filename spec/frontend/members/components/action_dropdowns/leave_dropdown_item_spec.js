import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LeaveGroupDropdownItem from '~/members/components/action_dropdowns/leave_dropdown_item.vue';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import { LEAVE_MODAL_ID } from '~/members/constants';
import { member, permissions } from '../../mock_data';

describe('LeaveGroupDropdownItem', () => {
  let wrapper;
  const text = 'dummy';

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(LeaveGroupDropdownItem, {
      propsData: {
        member,
        permissions,
        ...propsData,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      slots: {
        default: text,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders with a danger variant', () => {
    expect(findDropdownItem().props('variant')).toEqual('danger');
  });

  it('contains LeaveModal component', () => {
    const leaveModal = wrapper.findComponent(LeaveModal);

    expect(leaveModal.props()).toEqual({ member, permissions });
  });

  it('binds to the LeaveModal component', () => {
    const binding = getBinding(findDropdownItem().element, 'gl-modal');

    expect(binding.value).toBe(LEAVE_MODAL_ID);
  });
});
