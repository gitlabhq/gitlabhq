import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import { STATUS_LABELS, STATUS_TRIGGERED, STATUS_ACKNOWLEDGED } from '~/sidebar/constants';

describe('EscalationStatus', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = mountExtended(EscalationStatus, {
      propsData: {
        value: STATUS_TRIGGERED,
        ...props,
      },
    });
  }

  const findDropdownComponent = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownMenu = () => findDropdownComponent().find('.dropdown-menu');
  const toggleDropdown = async () => {
    await findDropdownComponent().findComponent('button').trigger('click');
    await waitForPromises();
  };

  describe('status', () => {
    it('shows the current status', () => {
      createComponent({ value: STATUS_ACKNOWLEDGED });

      expect(findDropdownComponent().props('text')).toBe(STATUS_LABELS[STATUS_ACKNOWLEDGED]);
    });

    it('shows the None option when status is null', () => {
      createComponent({ value: null });

      expect(findDropdownComponent().props('text')).toBe('None');
    });
  });

  describe('events', () => {
    it('selects an item', async () => {
      createComponent();

      await findDropdownItems().at(1).vm.$emit('click');

      expect(wrapper.emitted().input[0][0]).toBe(STATUS_ACKNOWLEDGED);
    });
  });

  describe('close behavior', () => {
    it('allows the dropdown to be closed by default', async () => {
      createComponent();
      // Open dropdown
      await toggleDropdown();
      jest.runOnlyPendingTimers();
      await nextTick();

      expect(findDropdownMenu().classes('show')).toBe(true);

      // Attempt to close dropdown
      await toggleDropdown();

      expect(findDropdownMenu().classes('show')).toBe(false);
    });

    it('preventDropdownClose prevents the dropdown from closing', async () => {
      createComponent({ preventDropdownClose: true });
      // Open dropdown
      await toggleDropdown();
      jest.runOnlyPendingTimers();
      await nextTick();

      expect(findDropdownMenu().classes('show')).toBe(true);

      // Attempt to close dropdown
      await toggleDropdown();

      expect(findDropdownMenu().classes('show')).toBe(true);
    });
  });
});
