import { shallowMount } from '@vue/test-utils';
import GroupFilter from '~/search/sidebar/components/group_filter.vue';
import ProjectFilter from '~/search/sidebar/components/project_filter.vue';
import AllScopesStartFilters from '~/search/sidebar/components/all_scopes_start_filters.vue';

describe('GlobalSearch AllScopesStartFilters', () => {
  let wrapper;

  const findGroupFilter = () => wrapper.findComponent(GroupFilter);
  const findProjectFilter = () => wrapper.findComponent(ProjectFilter);

  const createComponent = () => {
    wrapper = shallowMount(AllScopesStartFilters);
  };

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders ArchivedFilter', () => {
      expect(findGroupFilter().exists()).toBe(true);
    });

    it('renders FiltersTemplate', () => {
      expect(findProjectFilter().exists()).toBe(true);
    });
  });
});
