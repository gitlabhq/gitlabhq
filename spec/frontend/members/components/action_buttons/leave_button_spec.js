import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import LeaveButton from '~/members/components/action_buttons/leave_button.vue';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import { LEAVE_MODAL_ID } from '~/members/constants';
import { member } from '../../mock_data';

describe('LeaveButton', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(LeaveButton, {
      propsData: {
        member,
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
        GlModal: createMockDirective(),
      },
    });
  };

  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a tooltip', () => {
    const button = findButton();

    expect(getBinding(button.element, 'gl-tooltip')).not.toBeUndefined();
    expect(button.attributes('title')).toBe('Leave');
  });

  it('sets `aria-label` attribute', () => {
    expect(findButton().attributes('aria-label')).toBe('Leave');
  });

  it('renders leave modal', () => {
    const leaveModal = wrapper.find(LeaveModal);

    expect(leaveModal.exists()).toBe(true);
    expect(leaveModal.props('member')).toEqual(member);
  });

  it('triggers leave modal', () => {
    const binding = getBinding(findButton().element, 'gl-modal');

    expect(binding).not.toBeUndefined();
    expect(binding.value).toBe(LEAVE_MODAL_ID);
  });
});
