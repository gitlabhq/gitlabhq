import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import {
  STATUS_LABELS,
  STATUS_TRIGGERED,
  STATUS_ACKNOWLEDGED,
} from '~/sidebar/components/incidents/constants';

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

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownComponent = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

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
});
