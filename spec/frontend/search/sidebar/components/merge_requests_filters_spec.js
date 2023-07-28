import { shallowMount } from '@vue/test-utils';
import MergeRequestsFilters from '~/search/sidebar/components/merge_requests_filters.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';
import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';

describe('GlobalSearch MergeRequestsFilters', () => {
  let wrapper;

  const findStatusFilter = () => wrapper.findComponent(StatusFilter);
  const findFiltersTemplate = () => wrapper.findComponent(FiltersTemplate);

  const createComponent = () => {
    wrapper = shallowMount(MergeRequestsFilters);
  };

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders ConfidentialityFilter', () => {
      expect(findStatusFilter().exists()).toBe(true);
    });

    it('renders FiltersTemplate', () => {
      expect(findFiltersTemplate().exists()).toBe(true);
    });
  });
});
