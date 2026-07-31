import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_QUERY,
  MOCK_AGGREGATIONS,
  MOCK_LANGUAGE_AGGREGATIONS_BUCKETS,
} from 'jest/search/mock_data';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import CheckboxFilter from '~/search/sidebar/components/language_filter/checkbox_filter.vue';

Vue.use(Vuex);

describe('GlobalSearchSidebarLanguageFilter', () => {
  let wrapper;
  let trackingSpy;

  const actionSpies = {
    fetchAllAggregation: jest.fn(),
    applyQuery: jest.fn(),
  };

  const getterSpies = {
    languageAggregationBuckets: jest.fn(() => MOCK_LANGUAGE_AGGREGATIONS_BUCKETS),
    queryLanguageFilters: jest.fn(() => []),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        urlQuery: MOCK_QUERY,
        aggregations: MOCK_AGGREGATIONS,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(LanguageFilter, {
      store,
      stubs: {
        CheckboxFilter,
      },
    });
  };

  const findCheckboxFilter = () => wrapper.findComponent(CheckboxFilter);
  const findShowMoreButton = () => wrapper.findComponentByTestId('show-more-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findHasOverMax = () => wrapper.findByTestId('has-over-max-text');
  const findRefreshingIcon = () => wrapper.findByTestId('language-filter-refreshing-icon');
  const findListContainer = () => wrapper.findByTestId('language-filter-list-container');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('renders checkbox-filter', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders all checkbox-filter checkboxes', () => {
      // 11th checkbox is hidden
      expect(findAllCheckboxes()).toHaveLength(10);
    });

    it('renders Show More button', () => {
      expect(findShowMoreButton().exists()).toBe(true);
    });

    it("doesn't render Alert", () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('Show All button works', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it(`renders 100 items`, async () => {
      findShowMoreButton().vm.$emit('click');

      await nextTick();

      expect(findAllCheckboxes()).toHaveLength(100);
    });

    it('sends tracking information when show more clicked', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith('search:agreggations:language:click', 'Show More', {
        label: 'AllFilters',
      });
    });

    it(`renders more then 10 text`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findHasOverMax().exists()).toBe(true);
    });

    it('sends tracking information when show more clicked and max item reached', () => {
      findShowMoreButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith('search:agreggations:language:show', 'Filters', {
        label: 'Max Shown',
        property: `More than 10 filters to show`,
      });
    });

    it(`doesn't render show more button after click`, async () => {
      findShowMoreButton().vm.$emit('click');
      await nextTick();
      expect(findShowMoreButton().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent({});
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });
    afterEach(() => {
      unmockTracking();
    });

    it('uses getter languageAggregationBuckets', () => {
      expect(getterSpies.languageAggregationBuckets).toHaveBeenCalled();
    });

    it('uses action fetchAllAggregation', () => {
      expect(actionSpies.fetchAllAggregation).toHaveBeenCalled();
    });
  });

  // A background refresh (e.g. after the user changes the search term) keeps
  // the previous buckets on screen so the sidebar doesn't flash empty. During
  // that window we dim the list and show an inline spinner so it is obvious
  // the counts are being refreshed.
  describe('refreshing state', () => {
    it('does not render the spinner when aggregations are not fetching', () => {
      createComponent({ aggregations: { fetching: false, error: false, data: [] } });

      expect(findRefreshingIcon().exists()).toBe(false);
    });

    it('renders an inline spinner while aggregations are fetching', () => {
      createComponent({ aggregations: { fetching: true, error: false, data: [] } });

      expect(findRefreshingIcon().exists()).toBe(true);
    });

    it('dims the list and marks it aria-busy while fetching', () => {
      createComponent({ aggregations: { fetching: true, error: false, data: [] } });
      const container = findListContainer().element;

      expect(container.classList).toContain('gl-opacity-6');
      expect(container.classList).toContain('gl-pointer-events-none');
      expect(container.getAttribute('aria-busy')).toBe('true');
    });

    it('does not dim the list when fetching is false', () => {
      createComponent({ aggregations: { fetching: false, error: false, data: [] } });
      const container = findListContainer().element;

      expect(container.classList).not.toContain('gl-opacity-6');
      // Vue omits the attribute entirely when the bound value is falsy, so we
      // assert its absence rather than a literal "false" string.
      expect(container.hasAttribute('aria-busy')).toBe(false);
    });
  });
});
