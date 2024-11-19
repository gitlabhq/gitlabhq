import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlFormCheckboxGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import ForksFilter from '~/search/sidebar/components/forks_filter/index.vue';

Vue.use(Vuex);
const { bindInternalEventDocument } = useMockInternalEventsTracking();

describe('ForksFilter', () => {
  let wrapper;

  const defaultActions = {
    setQuery: jest.fn(),
  };

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
      actions: defaultActions,
    });

    wrapper = shallowMountExtended(ForksFilter, {
      store,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findCheckboxFilter = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findCheckboxFilterLabel = () => wrapper.findByTestId('tooltip-checkbox-label');
  const findTitle = () => wrapper.findByTestId('archived-filter-title');

  describe('old sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: false });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders the divider', () => {
      expect(findTitle().text()).toBe('Forks');
    });

    it('wraps the label element with a tooltip', () => {
      const tooltip = getBinding(findCheckboxFilterLabel().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Include search results from forked projects');
    });
  });

  describe('new sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: true });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it("doesn't render the divider", () => {
      expect(findTitle().text()).toBe('Forks');
    });

    it('wraps the label element with a tooltip', () => {
      const tooltip = getBinding(findCheckboxFilterLabel().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Include search results from forked projects');
    });
  });

  describe.each`
    include_forked | checkboxState
    ${'true'}      | ${'true'}
    ${'sdfsdf'}    | ${'false'}
    ${''}          | ${'false'}
    ${'false'}     | ${'false'}
  `('selectedFilter', ({ include_forked, checkboxState }) => {
    beforeEach(() => {
      createComponent({ urlQuery: { include_forked } });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().attributes('checked')).toBe(checkboxState);
    });
  });

  describe('selectedFilter logic', () => {
    beforeEach(() => {
      createComponent();
    });

    it('correctly executes setQuery without mutating the input', () => {
      const selectedFilter = [false];
      findCheckboxFilter().vm.$emit('input', selectedFilter);

      expect(defaultActions.setQuery).toHaveBeenCalledWith(expect.any(Object), {
        key: 'include_forked',
        value: 'false',
      });
      expect(selectedFilter).toEqual([false]);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent({
        urlQuery: {
          search: 'test',
        },
      });
    });

    it(`dispatches internal click_zoekt_include_forks_on_search_results_page`, () => {
      findCheckboxFilter().vm.$emit('change');
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_zoekt_include_forks_on_search_results_page',
        {},
        undefined,
      );
    });
  });
});
