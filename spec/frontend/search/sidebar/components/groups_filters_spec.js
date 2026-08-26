import { shallowMount } from '@vue/test-utils';
import GroupsFilters from '~/search/sidebar/components/groups_filters.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';

describe('GlobalSearch GroupsFilters', () => {
  let wrapper;

  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findFiltersTemplate = () => wrapper.findComponent(FiltersTemplate);

  const createComponent = () => {
    wrapper = shallowMount(GroupsFilters);
  };

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders ArchivedFilter', () => {
      expect(findArchivedFilter().exists()).toBe(true);
    });

    it('renders FiltersTemplate', () => {
      expect(findFiltersTemplate().exists()).toBe(true);
    });
  });
});
