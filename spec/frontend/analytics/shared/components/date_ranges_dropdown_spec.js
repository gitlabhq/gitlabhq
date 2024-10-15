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
    startDate: new Date('2023-09-07T00:00:00.000Z'),
    endDate: new Date('2023-09-14T00:00:00.000Z'),
  };
  const mockLast30Days = {
    text: 'Last month',
    value: last30DaysValue,
    startDate: new Date('2023-08-15T00:00:00.000Z'),
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
  const findDateRangeString = () => wrapper.findByTestId('predefined-date-range-string');
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

      it('should display date range string', () => {
        expect(findDateRangeString().exists()).toBe(true);
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

      it('should hide date range string', () => {
        expect(findDateRangeString().exists()).toBe(false);
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

  describe('date range string', () => {
    it.each`
      selected           | expectedDates
      ${lastWeekValue}   | ${'Sep 7 – 14, 2023'}
      ${last30DaysValue} | ${'Aug 15 – Sep 14, 2023'}
    `('should display correct dates selected', ({ selected, expectedDates }) => {
      createComponent({ props: { selected } });

      expect(wrapper.findByText(expectedDates).exists()).toBe(true);
    });

    it('should not render if disableDateRangeString is set', () => {
      createComponent({ props: { disableDateRangeString: true, selected: lastWeekValue } });
      expect(findDateRangeString().exists()).toBe(false);
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

    describe('custom date range option is selected', () => {
      beforeEach(async () => {
        findListBox().vm.$emit('select', customDateRangeValue);

        await nextTick();
      });

      it('should hide info icon', () => {
        expect(findHelpIcon().exists()).toBe(false);
      });
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
