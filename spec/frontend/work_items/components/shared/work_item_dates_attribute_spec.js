import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import WorkItemDatesAttribute from '~/work_items/components/shared/work_item_dates_attribute.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('WorkItemDatesAttribute component', () => {
  // July 6th, 2020
  useFakeDate(2020, 6, 6);

  let wrapper;

  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(WorkItemDatesAttribute, {
      propsData,
      stubs: {
        WorkItemAttribute,
      },
    });
  };

  describe('when there is no start date and no due date', () => {
    it('renders nothing', () => {
      createComponent();

      expect(findWorkItemAttribute().exists()).toBe(false);
    });
  });

  describe('rendered dates text', () => {
    it('renders the date range when both dates are provided', () => {
      createComponent({ startDate: '2020-11-30', dueDate: '2020-12-12' });

      expect(findWorkItemAttribute().props('title')).toBe('Nov 30 – Dec 12, 2020');
    });

    it('renders "No start date" prefix when only due date is provided', () => {
      createComponent({ dueDate: '2020-12-12' });

      expect(findWorkItemAttribute().props('title')).toBe('No start date – Dec 12, 2020');
    });

    it('renders "No due date" suffix when only start date is provided', () => {
      createComponent({ startDate: '2020-11-30' });

      expect(findWorkItemAttribute().props('title')).toBe('Nov 30, 2020 – No due date');
    });
  });

  describe('due date status', () => {
    describe('when due date is in the past', () => {
      it('renders the overdue icon and tooltip', () => {
        createComponent({ dueDate: '2020-01-01' });

        expect(findIcon().props()).toMatchObject({
          variant: 'danger',
          name: 'calendar-overdue',
        });
        expect(findWorkItemAttribute().props('tooltipText')).toBe('Dates (overdue)');
      });

      it('does not render as overdue when closed', () => {
        createComponent({ dueDate: '2020-01-01', isClosed: true });

        expect(findIcon().props()).toMatchObject({
          variant: 'current',
          name: 'calendar',
        });
        expect(findWorkItemAttribute().props('tooltipText')).toBe('Dates');
      });
    });

    describe('when due date is approaching', () => {
      it('classifies today as approaching, not overdue', () => {
        createComponent({ dueDate: '2020-07-06' });

        expect(findIcon().props()).toMatchObject({
          variant: 'warning',
          name: 'calendar-due',
        });
        expect(findWorkItemAttribute().props('tooltipText')).toBe('Dates (due soon)');
      });

      it('renders the approaching icon when due within 6 days', () => {
        createComponent({ dueDate: '2020-07-12' });

        expect(findIcon().props()).toMatchObject({
          variant: 'warning',
          name: 'calendar-due',
        });
      });

      it('renders the neutral icon when due exactly 7 days away', () => {
        createComponent({ dueDate: '2020-07-13' });

        expect(findIcon().props()).toMatchObject({
          variant: 'current',
          name: 'calendar',
        });
      });

      it('does not render as approaching when closed', () => {
        createComponent({ dueDate: '2020-07-09', isClosed: true });

        expect(findIcon().props()).toMatchObject({
          variant: 'current',
          name: 'calendar',
        });
      });
    });

    describe('when there is only a start date', () => {
      it('renders the neutral icon and tooltip', () => {
        createComponent({ startDate: '2020-11-30' });

        expect(findIcon().props()).toMatchObject({
          variant: 'current',
          name: 'calendar',
        });
        expect(findWorkItemAttribute().props('tooltipText')).toBe('Dates');
      });
    });
  });

  describe('wrapper attributes', () => {
    it('renders default anchor id, wrapper and tooltip placement', () => {
      createComponent({ dueDate: '2020-12-12' });

      expect(wrapper.findByTestId('issuable-due-date').element.tagName).toBe('BUTTON');
      expect(findWorkItemAttribute().props('tooltipPlacement')).toBe('top');
    });

    it('forwards anchor id, wrapper component and icon size', () => {
      createComponent({
        dueDate: '2020-12-12',
        anchorId: 'item-dates',
        wrapperComponent: 'div',
        iconSize: 12,
      });

      expect(wrapper.findByTestId('item-dates').element.tagName).toBe('DIV');
      expect(findIcon().props('size')).toBe(12);
    });
  });
});
