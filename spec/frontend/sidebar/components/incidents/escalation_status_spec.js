import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import { STATUS_LABELS, STATUS_TRIGGERED, STATUS_ACKNOWLEDGED } from '~/sidebar/constants';

describe('EscalationStatus', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = mount(EscalationStatus, {
      propsData: {
        value: STATUS_TRIGGERED,
        ...props,
      },
    });
  }

  const findDropdownComponent = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownItem = (at) => wrapper.findAllComponents(GlListboxItem).at(at);

  describe('status', () => {
    it('shows the current status', () => {
      createComponent({ value: STATUS_ACKNOWLEDGED });

      expect(findDropdownComponent().props('toggleText')).toBe(STATUS_LABELS[STATUS_ACKNOWLEDGED]);
    });

    it('shows the None option when status is null', () => {
      createComponent({ value: null });

      expect(findDropdownComponent().props('toggleText')).toBe('None');
    });
    it('renders headerText when it is provided', () => {
      const headerText = 'some text';
      createComponent({ headerText });

      expect(findDropdownComponent().text()).toContain(headerText);
    });

    it('renders subtext when it is provided', () => {
      const subText = 'some subtext';
      const statusSubtexts = { [STATUS_ACKNOWLEDGED]: subText };
      createComponent({ statusSubtexts });

      expect(findDropdownItem(1).text()).toContain(subText);
    });
  });

  describe('events', () => {
    it('selects an item', () => {
      createComponent();
      findDropdownComponent().vm.$emit('select', STATUS_ACKNOWLEDGED);

      expect(wrapper.emitted().input[0][0]).toBe(STATUS_ACKNOWLEDGED);
    });
  });
});
