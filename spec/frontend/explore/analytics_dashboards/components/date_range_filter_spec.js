import { GlCollapsibleListbox, GlDaterangePicker, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DateRangeFilter from '~/explore/analytics_dashboards/components/date_range_filter.vue';
import {
  DEFAULT_DATE_RANGE_OPTIONS,
  DATE_RANGE_OPTIONS,
  TODAY,
  DEFAULT_SELECTED_DATE_RANGE_OPTION,
} from '~/explore/analytics_dashboards/components/constants';
import { dateRangeOptionToFilter } from '~/explore/analytics_dashboards/components/utils';

describe('DateRangeFilter', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const AVAILABLE_OPTIONS = DEFAULT_DATE_RANGE_OPTIONS.map((key) => DATE_RANGE_OPTIONS[key]);
  const dateRangeOption = AVAILABLE_OPTIONS.find((option) => !option.showDateRangePicker);
  const customRangeOption = AVAILABLE_OPTIONS.find((option) => option.showDateRangePicker);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DateRangeFilter, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        ...props,
      },
    });
  };

  const findDateRangePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findCollapsibleListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findHelpIcon = () => wrapper.findComponent(GlIcon);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a dropdown with the value set to the default selected option', () => {
      expect(findCollapsibleListBox().props().selected).toBe(
        DATE_RANGE_OPTIONS[DEFAULT_SELECTED_DATE_RANGE_OPTION].key,
      );
    });

    it('renders a dropdown item for each option', () => {
      AVAILABLE_OPTIONS.forEach((option, idx) => {
        expect(findCollapsibleListBox().props('items').at(idx).text).toBe(option.text);
      });
    });

    it('emits the selected date range when a dropdown item with a date range is clicked', () => {
      findCollapsibleListBox().vm.$emit('select', dateRangeOption.key);

      expect(wrapper.emitted('change')).toStrictEqual([[dateRangeOptionToFilter(dateRangeOption)]]);
    });

    it('should show an icon with a tooltip explaining dates are in UTC', () => {
      const helpIcon = findHelpIcon();
      const tooltip = getBinding(helpIcon.element, 'gl-tooltip');

      expect(helpIcon.props('name')).toBe('information-o');
      expect(helpIcon.attributes('title')).toBe(
        'Dates and times are displayed in the UTC timezone.',
      );
      expect(tooltip).toBeDefined();
    });

    it('does not have the class "gl-flex-col"', () => {
      expect(wrapper.classes()).not.toContain('gl-flex-col');
    });
  });

  describe('with a default option', () => {
    beforeEach(() => {
      createWrapper({ defaultOption: customRangeOption.key });
    });

    it('selects the provided default option', () => {
      expect(findCollapsibleListBox().props().selected).toBe(customRangeOption.key);
    });
  });

  describe('options', () => {
    it('overrides the default options', () => {
      const options = ['7d', 'today'];
      createWrapper({ options });

      const res = findCollapsibleListBox()
        .props('items')
        .map(({ value }) => value);

      expect(res).toEqual(options);
    });

    it('filters out invalid options', () => {
      createWrapper({ options: [...DEFAULT_DATE_RANGE_OPTIONS, '25d'] });

      expect(
        findCollapsibleListBox()
          .props('items')
          .map(({ value }) => value),
      ).not.toContain('25d');
    });
  });

  describe('date range picker', () => {
    describe('by default', () => {
      const { startDate, endDate } = DATE_RANGE_OPTIONS[DEFAULT_SELECTED_DATE_RANGE_OPTION];

      beforeEach(() => {
        createWrapper({ startDate, endDate });
      });

      it('adds the class "gl-flex-col" when a custom date range is selected', async () => {
        await findCollapsibleListBox().vm.$emit('select', customRangeOption.key);

        expect(wrapper.classes()).toContain('gl-flex-col');
      });

      it('does not emit a new date range when the option shows the date range picker', async () => {
        await findCollapsibleListBox().vm.$emit('select', customRangeOption.key);

        expect(wrapper.emitted('change')).toBeUndefined();
      });

      it('shows the date range picker with the provided date range when the option enables it', async () => {
        expect(findDateRangePicker().exists()).toBe(false);

        await findCollapsibleListBox().vm.$emit('select', customRangeOption.key);

        expect(findDateRangePicker().props()).toMatchObject({
          toLabel: 'To',
          fromLabel: 'From',
          tooltip: '',
          defaultMaxDate: TODAY,
          maxDateRange: 0,
          value: {
            startDate,
            endDate,
          },
          defaultStartDate: startDate,
          defaultEndDate: endDate,
        });
      });
    });

    describe.each([
      { dateRangeLimit: 0, expectedTooltip: 'Dates and times are displayed in the UTC timezone.' },
      {
        dateRangeLimit: 1,
        expectedTooltip:
          'Dates and times are displayed in the UTC timezone. Date range is limited to 1 day.',
      },
      {
        dateRangeLimit: 12,
        expectedTooltip:
          'Dates and times are displayed in the UTC timezone. Date range is limited to 12 days.',
      },
      {
        dateRangeLimit: 31,
        expectedTooltip:
          'Dates and times are displayed in the UTC timezone. Date range is limited to 31 days.',
      },
    ])(
      'when given a date range limit of $dateRangeLimit',
      ({ dateRangeLimit, expectedTooltip }) => {
        beforeEach(() => {
          createWrapper({ dateRangeLimit });
        });

        it('shows the date range picker with date range limit applied', async () => {
          expect(findDateRangePicker().exists()).toBe(false);

          await findCollapsibleListBox().vm.$emit('select', customRangeOption.key);

          expect(findDateRangePicker().props()).toMatchObject({
            maxDateRange: dateRangeLimit,
          });
          expect(findHelpIcon().attributes('title')).toBe(expectedTooltip);
        });
      },
    );
  });
});
