import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlIcon } from '@gitlab/ui';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('DateRangesDropdown', () => {
  let wrapper;

  const customDateRangeValue = 'custom';
  const lastWeekValue = 'lastWeek';
  const last30DaysValue = 'lastMonth';
  const mockLastWeek = {
    text: 'Last week',
    value: lastWeekValue,
    startDate: new Date('2023-09-08T00:00:00.000Z'),
    endDate: new Date('2023-09-14T00:00:00.000Z'),
  };
  const mockLast30Days = {
    text: 'Last month',
    value: last30DaysValue,
    startDate: new Date('2023-08-16T00:00:00.000Z'),
    endDate: new Date('2023-09-14T00:00:00.000Z'),
  };
  const mockCustomDateRangeItem = {
    text: 'Custom',
    value: customDateRangeValue,
  };
  const mockDateRanges = [mockLastWeek, mockLast30Days];
  const mockItems = mockDateRanges.map(({ text, value }) => ({ text, value }));
  const mockTooltipText = 'Max date range is 180 days';

  const createComponent = ({ props = {}, dateRangeOptions = mockDateRanges } = {}) => {
    wrapper = shallowMountExtended(DateRangesDropdown, {
      propsData: {
        dateRangeOptions,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDaysSelectedCount = () => wrapper.findByTestId('predefined-date-range-days-count');
  const findHelpIcon = () => wrapper.findComponent(GlIcon);

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should pass items to listbox `items` prop in correct order', () => {
      expect(findListBox().props('items')).toStrictEqual([...mockItems, mockCustomDateRangeItem]);
    });

    it('should display first option as selected', () => {
      expect(findListBox().props('selected')).toBe(lastWeekValue);
    });

    it('should not display info icon', () => {
      expect(findHelpIcon().exists()).toBe(false);
    });

    describe.each`
      dateRangeValue     | dateRangeItem
      ${lastWeekValue}   | ${mockLastWeek}
      ${last30DaysValue} | ${mockLast30Days}
    `('when $dateRangeValue date range is selected', ({ dateRangeValue, dateRangeItem }) => {
      beforeEach(async () => {
        findListBox().vm.$emit('select', dateRangeValue);

        await nextTick();
      });

      it('should emit `selected` event with value and date range', () => {
        const { text, ...dateRangeProps } = dateRangeItem;

        expect(wrapper.emitted('selected')).toEqual([[dateRangeProps]]);
      });

      it('should display days selected indicator', () => {
        expect(findDaysSelectedCount().exists()).toBe(true);
      });

      it('should not emit `customDateRangeSelected` event', () => {
        expect(wrapper.emitted('customDateRangeSelected')).toBeUndefined();
      });
    });

    describe('when the custom date range option is selected', () => {
      beforeEach(async () => {
        findListBox().vm.$emit('select', customDateRangeValue);

        await nextTick();
      });

      it('should emit `customDateRangeSelected` event', () => {
        expect(wrapper.emitted('customDateRangeSelected')).toHaveLength(1);
      });

      it('should hide days selected indicator', () => {
        expect(findDaysSelectedCount().exists()).toBe(false);
      });

      it('should not emit `selected` event', () => {
        expect(wrapper.emitted('selected')).toBeUndefined();
      });
    });
  });

  describe('when a date range is preselected', () => {
    beforeEach(() => {
      createComponent({ props: { selected: 'lastMonth' } });
    });

    it('should display preselected date range as selected in listbox', () => {
      expect(findListBox().props('selected')).toBe(last30DaysValue);
    });
  });

  describe('days selected indicator', () => {
    it.each`
      selected           | includeEndDateInDaysSelected | expectedDaysCount
      ${lastWeekValue}   | ${true}                      | ${7}
      ${last30DaysValue} | ${true}                      | ${30}
      ${lastWeekValue}   | ${false}                     | ${6}
      ${last30DaysValue} | ${false}                     | ${29}
    `(
      'should display correct days selected when includeEndDateInDaysSelected=$includeEndDateInDaysSelected',
      ({ selected, includeEndDateInDaysSelected, expectedDaysCount }) => {
        createComponent({ props: { selected, includeEndDateInDaysSelected } });

        expect(wrapper.findByText(`${expectedDaysCount} days selected`).exists()).toBe(true);
      },
    );

    it('should not rendered the indicator if disableSelectedDayCount is set', () => {
      createComponent({ props: { disableSelectedDayCount: true, selected: lastWeekValue } });
      expect(findDaysSelectedCount().exists()).toBe(false);
    });
  });

  describe('when the `tooltip` prop is set', () => {
    beforeEach(() => {
      createComponent({ props: { tooltip: mockTooltipText } });
    });

    it('should display info icon with tooltip', () => {
      const helpIcon = findHelpIcon();
      const tooltip = getBinding(helpIcon.element, 'gl-tooltip');

      expect(helpIcon.props('name')).toBe('information-o');
      expect(helpIcon.attributes('title')).toBe(mockTooltipText);

      expect(tooltip).toBeDefined();
    });
  });

  describe('when `includeCustomDateRangeOption` = false', () => {
    beforeEach(() => {
      createComponent({ props: { includeCustomDateRangeOption: false } });
    });

    it('should pass items without custom date range option to listbox `items` prop', () => {
      expect(findListBox().props('items')).toEqual(mockItems);
    });
  });
});
