import { GlEmptyState, GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTicketModal from '~/work_items/components/work_item_ticket_modal.vue';

describe('WorkItemTicketModal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemTicketModal, {
      stubs: { GlSprintf },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    createComponent();
  });

  it('renders a visible modal', () => {
    expect(findModal().props()).toMatchObject({
      modalId: 'work-item-ticket-modal',
      size: 'sm',
      visible: true,
      ariaLabel: 'A new experience for Tickets',
    });
    expect(findModal().attributes('hide-footer')).toBe('');
  });

  it('renders the empty state with the migration message', () => {
    expect(findEmptyState().props('title')).toBe('A new experience for Tickets');
    expect(findEmptyState().text()).toContain('Your Service Desk items are now Tickets');
  });

  it('emits `hide` when the modal is hidden', () => {
    findModal().vm.$emit('hide');

    expect(wrapper.emitted('hide')).toEqual([[]]);
  });
});
