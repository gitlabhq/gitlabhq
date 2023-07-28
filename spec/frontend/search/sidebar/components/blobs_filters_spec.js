import { shallowMount } from '@vue/test-utils';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';

describe('GlobalSearch BlobsFilters', () => {
  let wrapper;

  const findLanguageFilter = () => wrapper.findComponent(LanguageFilter);
  const findFiltersTemplate = () => wrapper.findComponent(FiltersTemplate);

  const createComponent = () => {
    wrapper = shallowMount(BlobsFilters);
  };

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders FiltersTemplate', () => {
      expect(findLanguageFilter().exists()).toBe(true);
    });

    it('renders ConfidentialityFilter', () => {
      expect(findFiltersTemplate().exists()).toBe(true);
    });
  });
});
