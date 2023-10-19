import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Daterange from '~/analytics/shared/components/daterange.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import FilterBar from '~/analytics/cycle_analytics/components/filter_bar.vue';
import ValueStreamFilters from '~/analytics/cycle_analytics/components/value_stream_filters.vue';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import {
  DATE_RANGE_LAST_30_DAYS_VALUE,
  DATE_RANGE_CUSTOM_VALUE,
  LAST_30_DAYS,
} from '~/analytics/shared/constants';
import { useFakeDate } from 'helpers/fake_date';
import { currentGroup, selectedProjects } from '../mock_data';

const { path } = currentGroup;
const groupPath = `groups/${path}`;
const defaultFeatureFlags = {
  vsaPredefinedDateRanges: false,
};

const startDate = LAST_30_DAYS;
const endDate = new Date('2019-01-14T00:00:00.000Z');

function createComponent({ props = {}, featureFlags = defaultFeatureFlags } = {}) {
  return shallowMountExtended(ValueStreamFilters, {
    propsData: {
      selectedProjects,
      groupPath,
      namespacePath: currentGroup.fullPath,
      startDate,
      endDate,
      ...props,
    },
    provide: {
      glFeatures: {
        ...featureFlags,
      },
    },
  });
}

describe('ValueStreamFilters', () => {
  useFakeDate(2019, 0, 14, 10, 10);

  let wrapper;

  const findProjectsDropdown = () => wrapper.findComponent(ProjectsDropdownFilter);
  const findDateRangePicker = () => wrapper.findComponent(Daterange);
  const findFilterBar = () => wrapper.findComponent(FilterBar);
  const findDateRangesDropdown = () => wrapper.findComponent(DateRangesDropdown);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('will render the filter bar', () => {
    expect(findFilterBar().exists()).toBe(true);
  });

  it('will render the projects dropdown', () => {
    expect(findProjectsDropdown().exists()).toBe(true);
    expect(wrapper.findComponent(ProjectsDropdownFilter).props()).toEqual(
      expect.objectContaining({
        queryParams: wrapper.vm.projectsQueryParams,
        multiSelect: wrapper.vm.$options.multiProjectSelect,
      }),
    );
  });

  it('will render the date range picker', () => {
    expect(findDateRangePicker().exists()).toBe(true);
  });

  it('will not render the date ranges dropdown', () => {
    expect(findDateRangesDropdown().exists()).toBe(false);
  });

  it('will emit `selectProject` when a project is selected', () => {
    findProjectsDropdown().vm.$emit('selected');

    expect(wrapper.emitted('selectProject')).not.toBeUndefined();
  });

  it('will emit `setDateRange` when the date range changes', () => {
    findDateRangePicker().vm.$emit('change');

    expect(wrapper.emitted('setDateRange')).not.toBeUndefined();
  });

  describe('hasDateRangeFilter = false', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { hasDateRangeFilter: false } });
    });

    it('should not render the date range picker', () => {
      expect(findDateRangePicker().exists()).toBe(false);
    });
  });

  describe('hasProjectFilter = false', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { hasProjectFilter: false } });
    });

    it('will not render the project dropdown', () => {
      expect(findProjectsDropdown().exists()).toBe(false);
    });
  });

  describe('`vsaPredefinedDateRanges` feature flag is enabled', () => {
    const lastMonthValue = 'lastMonthValue';
    const mockDateRange = {
      value: lastMonthValue,
      startDate: new Date('2023-08-08T00:00:00.000Z'),
      endDate: new Date('2023-09-08T00:00:00.000Z'),
    };

    beforeEach(() => {
      wrapper = createComponent({ featureFlags: { vsaPredefinedDateRanges: true } });
    });

    it('should render date ranges dropdown', () => {
      expect(findDateRangesDropdown().exists()).toBe(true);
    });

    it('should not render date range picker', () => {
      expect(findDateRangePicker().exists()).toBe(false);
    });

    describe('when a date range is selected from the dropdown', () => {
      describe('predefined date range option', () => {
        beforeEach(async () => {
          findDateRangesDropdown().vm.$emit('selected', mockDateRange);

          await nextTick();
        });

        it('should emit `setDateRange` with date range', () => {
          const { value, ...dateRange } = mockDateRange;

          expect(wrapper.emitted('setDateRange')).toEqual([[dateRange]]);
        });

        it('should emit `setPredefinedDateRange` with correct value', () => {
          expect(wrapper.emitted('setPredefinedDateRange')).toEqual([[lastMonthValue]]);
        });
      });

      describe('custom date range option', () => {
        beforeEach(async () => {
          findDateRangesDropdown().vm.$emit('customDateRangeSelected');

          await nextTick();
        });

        it('should emit `setPredefinedDateRange` with custom date range value', () => {
          expect(wrapper.emitted('setPredefinedDateRange')).toEqual([[DATE_RANGE_CUSTOM_VALUE]]);
        });

        it('should not emit `setDateRange`', () => {
          expect(wrapper.emitted('setDateRange')).toBeUndefined();
        });
      });
    });

    describe.each`
      predefinedDateRange        | shouldRenderDateRangePicker | dateRangeType
      ${DATE_RANGE_CUSTOM_VALUE} | ${true}                     | ${'custom date range'}
      ${lastMonthValue}          | ${false}                    | ${'predefined date range'}
    `(
      'when the `predefinedDateRange` prop is set to a $dateRangeType',
      ({ predefinedDateRange, shouldRenderDateRangePicker }) => {
        beforeEach(() => {
          wrapper = createComponent({
            props: { predefinedDateRange },
            featureFlags: { vsaPredefinedDateRanges: true },
          });
        });

        it("should be passed into the dropdown's `selected` prop", () => {
          expect(findDateRangesDropdown().props('selected')).toBe(predefinedDateRange);
        });

        it(`should ${
          shouldRenderDateRangePicker ? '' : 'not'
        } render the date range picker`, () => {
          expect(findDateRangePicker().exists()).toBe(shouldRenderDateRangePicker);
        });
      },
    );

    describe('when the `predefinedDateRange` prop is null', () => {
      const laterStartDate = new Date('2018-12-01T00:00:00.000Z');
      const earlierStartDate = new Date('2019-01-01T00:00:00.000Z');
      const customEndDate = new Date('2019-02-01T00:00:00.000Z');

      describe.each`
        dateRange                                   | expectedDateRangeOption          | shouldRenderDateRangePicker | description
        ${{ startDate, endDate }}                   | ${DATE_RANGE_LAST_30_DAYS_VALUE} | ${false}                    | ${'is default'}
        ${{ startDate: laterStartDate, endDate }}   | ${DATE_RANGE_CUSTOM_VALUE}       | ${true}                     | ${'has a later start date than the default'}
        ${{ startDate: earlierStartDate, endDate }} | ${DATE_RANGE_CUSTOM_VALUE}       | ${true}                     | ${'has an earlier start date than the default'}
        ${{ startDate, endDate: customEndDate }}    | ${DATE_RANGE_CUSTOM_VALUE}       | ${true}                     | ${'has an end date that is not today'}
      `(
        'date range $description',
        ({ dateRange, expectedDateRangeOption, shouldRenderDateRangePicker }) => {
          beforeEach(() => {
            wrapper = createComponent({
              props: { predefinedDateRange: null, ...dateRange },
              featureFlags: { vsaPredefinedDateRanges: true },
            });
          });

          it("should set the dropdown's `selected` prop to the correct value", () => {
            expect(findDateRangesDropdown().props('selected')).toBe(expectedDateRangeOption);
          });

          it(`should ${
            shouldRenderDateRangePicker ? '' : 'not'
          } render the date range picker`, () => {
            expect(findDateRangePicker().exists()).toBe(shouldRenderDateRangePicker);
          });
        },
      );
    });

    describe('hasPredefinedDateRangesFilter = false', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: { hasPredefinedDateRangesFilter: false },
          featureFlags: { vsaPredefinedDateRanges: true },
        });
      });

      it('should not render the date ranges dropdown', () => {
        expect(findDateRangesDropdown().exists()).toBe(false);
      });
    });

    describe('hasDateRangeFilter = false', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: { hasDateRangeFilter: false },
          featureFlags: { vsaPredefinedDateRanges: true },
        });
      });

      it('should not render the date range picker', () => {
        expect(findDateRangePicker().exists()).toBe(false);
      });

      it('should remove custom date range option from date ranges dropdown', () => {
        expect(findDateRangesDropdown().props('includeCustomDateRangeOption')).toBe(false);
      });
    });
  });
});
