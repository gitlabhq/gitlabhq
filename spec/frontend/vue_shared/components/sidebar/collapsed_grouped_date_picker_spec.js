import { shallowMount } from '@vue/test-utils';

import CollapsedGroupedDatePicker from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
import CollapsedCalendarIcon from '~/vue_shared/components/sidebar/collapsed_calendar_icon.vue';

describe('CollapsedGroupedDatePicker', () => {
  let wrapper;

  const defaultProps = {
    showToggleSidebar: true,
  };

  const minDate = new Date('07/17/2016');
  const maxDate = new Date('07/17/2017');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CollapsedGroupedDatePicker, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findCollapsedCalendarIcon = () => wrapper.findComponent(CollapsedCalendarIcon);
  const findAllCollapsedCalendarIcons = () => wrapper.findAllComponents(CollapsedCalendarIcon);

  describe('toggleCollapse events', () => {
    it('should emit when collapsed-calendar-icon is clicked', () => {
      createComponent();

      findCollapsedCalendarIcon().trigger('click');

      expect(wrapper.emitted('toggleCollapse')[0]).toBeDefined();
    });
  });

  describe('minDate and maxDate', () => {
    it('should render both collapsed-calendar-icon', () => {
      createComponent({
        props: {
          minDate,
          maxDate,
        },
      });

      const icons = findAllCollapsedCalendarIcons();

      expect(icons.length).toBe(2);
      expect(icons.at(0).text()).toBe('Jul 17 2016');
      expect(icons.at(1).text()).toBe('Jul 17 2017');
    });
  });

  describe('minDate', () => {
    it('should render minDate in collapsed-calendar-icon', () => {
      createComponent({
        props: {
          minDate,
        },
      });

      const icons = findAllCollapsedCalendarIcons();

      expect(icons.length).toBe(1);
      expect(icons.at(0).text()).toBe('From Jul 17 2016');
    });
  });

  describe('maxDate', () => {
    it('should render maxDate in collapsed-calendar-icon', () => {
      createComponent({
        props: {
          maxDate,
        },
      });
      const icons = findAllCollapsedCalendarIcons();

      expect(icons.length).toBe(1);
      expect(icons.at(0).text()).toBe('Until Jul 17 2017');
    });
  });

  describe('no dates', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render None', () => {
      const icons = findAllCollapsedCalendarIcons();

      expect(icons.length).toBe(1);
      expect(icons.at(0).text()).toBe('None');
    });

    it('should have tooltip as `Start and due date`', () => {
      const icons = findAllCollapsedCalendarIcons();

      expect(icons.at(0).props('tooltipText')).toBe('Start and due date');
    });
  });
});
