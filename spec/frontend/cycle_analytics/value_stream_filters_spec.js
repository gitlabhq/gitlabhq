import { shallowMount } from '@vue/test-utils';
import Daterange from '~/analytics/shared/components/daterange.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import FilterBar from '~/cycle_analytics/components/filter_bar.vue';
import ValueStreamFilters from '~/cycle_analytics/components/value_stream_filters.vue';
import {
  createdAfter as startDate,
  createdBefore as endDate,
  currentGroup,
  selectedProjects,
} from './mock_data';

function createComponent(props = {}) {
  return shallowMount(ValueStreamFilters, {
    propsData: {
      selectedProjects,
      groupId: currentGroup.id,
      groupPath: currentGroup.fullPath,
      startDate,
      endDate,
      ...props,
    },
  });
}

describe('ValueStreamFilters', () => {
  let wrapper;

  const findProjectsDropdown = () => wrapper.findComponent(ProjectsDropdownFilter);
  const findDateRangePicker = () => wrapper.findComponent(Daterange);
  const findFilterBar = () => wrapper.findComponent(FilterBar);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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
      wrapper = createComponent({ hasDateRangeFilter: false });
    });

    it('will not render the date range picker', () => {
      expect(findDateRangePicker().exists()).toBe(false);
    });
  });

  describe('hasProjectFilter = false', () => {
    beforeEach(() => {
      wrapper = createComponent({ hasProjectFilter: false });
    });

    it('will not render the project dropdown', () => {
      expect(findProjectsDropdown().exists()).toBe(false);
    });
  });
});
