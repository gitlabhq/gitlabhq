import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import CommitsFilters from '~/search/sidebar/components/commits_filters.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import FiltersTemplate from '~/search/sidebar/components/filters_template.vue';

Vue.use(Vuex);

describe('GlobalSearch CommitsFilters', () => {
  let wrapper;

  const defaultGetters = {
    hasMissingProjectContext: () => true,
  };

  const createComponent = () => {
    const store = new Vuex.Store({
      getters: defaultGetters,
    });

    wrapper = shallowMount(CommitsFilters, {
      store,
    });
  };

  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);
  const findFiltersTemplate = () => wrapper.findComponent(FiltersTemplate);

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

  describe('hasMissingProjectContext getter', () => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => false;
      createComponent();
    });

    it('hides archived filter', () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });
  });
});
