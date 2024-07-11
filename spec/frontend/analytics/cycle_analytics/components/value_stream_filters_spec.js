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

const startDate = LAST_30_DAYS;
const endDate = new Date('2019-01-14T00:00:00.000Z');

function createComponent({ props = {} } = {}) {
  return shallowMountExtended(ValueStreamFilters, {
    propsData: {
      selectedProjects,
      groupPath,
      namespacePath: currentGroup.fullPath,
      startDate,
      endDate,
      ...props,
    },
  });
}

describe('ValueStreamFilters', () => {
  useFakeDate(2019, 0, 14, 10, 10);

  let wrapper;

  const findFilterDropdownsContainer = () => wrapper.findByTestId('vsa-filter-dropdowns-container');
  const findProjectsDropdown = () => wrapper.findComponent(ProjectsDropdownFilter);
  const findDateRangePicker = () => wrapper.findComponent(Daterange);
  const findFilterBar = () => wrapper.findComponent(FilterBar);
  const findDateRangesDropdown = () => wrapper.findComponent(DateRangesDropdown);

  describe('default', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('will render the filter bar', () => {
      expect(findFilterBar().exists()).toBe(true);
    });

    it('should render the filter dropdowns container', () => {
      expect(findFilterDropdownsContainer().exists()).toBe(true);
    });

    it('should render a separator between filtered search bar and dropdowns', () => {
      expect(wrapper.find('hr').exists()).toBe(true);
    });

    describe('filter dropdowns', () => {
      describe('projects dropdown', () => {
        it('will render the projects dropdown', () => {
          expect(findProjectsDropdown().exists()).toBe(true);
          expect(findProjectsDropdown().props()).toEqual(
            expect.objectContaining({
              queryParams: { first: 50, includeSubgroups: true },
              multiSelect: true,
            }),
          );
        });

        it('will emit `selectProject` when a project is selected', () => {
          findProjectsDropdown().vm.$emit('selected');

          expect(wrapper.emitted('selectProject')).toHaveLength(1);
        });
      });

      describe('date range filters', () => {
        it('should render date ranges dropdown', () => {
          expect(findDateRangesDropdown().props()).toMatchObject({
            selected: DATE_RANGE_LAST_30_DAYS_VALUE,
          });
        });

        it('should not render date range picker', () => {
          expect(findDateRangePicker().exists()).toBe(false);
        });

        describe('date ranges dropdown', () => {
          const lastMonthValue = 'lastMonthValue';
          const mockDateRange = {
            value: lastMonthValue,
            startDate: new Date('2023-08-08T00:00:00.000Z'),
            endDate: new Date('2023-09-08T00:00:00.000Z'),
          };

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
                expect(wrapper.emitted('setPredefinedDateRange')).toEqual([
                  [DATE_RANGE_CUSTOM_VALUE],
                ]);
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
        });

        describe('date range picker', () => {
          beforeEach(() => {
            wrapper = createComponent({
              props: { predefinedDateRange: DATE_RANGE_CUSTOM_VALUE },
            });
          });

          it('should emit `setDateRange` when the date range changes', () => {
            findDateRangePicker().vm.$emit('change');

            expect(wrapper.emitted('setDateRange')).toHaveLength(1);
          });
        });
      });
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

  describe('hasDateRangeFilter = false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: { hasDateRangeFilter: false },
      });
    });

    it('should not render the date range picker', () => {
      expect(findDateRangePicker().exists()).toBe(false);
    });

    it('should remove custom date range option from date ranges dropdown', () => {
      expect(findDateRangesDropdown().props('includeCustomDateRangeOption')).toBe(false);
    });
  });

  describe('hasPredefinedDateRangesFilter = false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: { hasPredefinedDateRangesFilter: false },
      });
    });

    it('should not render the date ranges dropdown', () => {
      expect(findDateRangesDropdown().exists()).toBe(false);
    });

    it('should render date range picker', () => {
      expect(findDateRangePicker().exists()).toBe(true);
    });
  });

  describe('hasProjectFilter=false, hasDateRangeFilter=false, and hasPredefinedDateRangesFilter=false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          hasProjectFilter: false,
          hasDateRangeFilter: false,
          hasPredefinedDateRangesFilter: false,
        },
      });
    });

    it('should not render the filter dropdowns container', () => {
      expect(findFilterDropdownsContainer().exists()).toBe(false);
    });

    it('should not render a separator between filtered search bar and dropdowns', () => {
      expect(wrapper.find('hr').exists()).toBe(false);
    });
  });
});
