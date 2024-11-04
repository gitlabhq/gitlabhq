import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlFormCheckboxGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';

Vue.use(Vuex);

describe('ArchivedFilter', () => {
  let wrapper;

  const defaultActions = {
    setQuery: jest.fn(),
  };

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
      actions: defaultActions,
    });

    wrapper = shallowMountExtended(ArchivedFilter, {
      store,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findCheckboxFilter = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findCheckboxFilterLabel = () => wrapper.findByTestId('label');
  const findTitle = () => wrapper.findByTestId('archived-filter-title');

  describe('old sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: false });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders the divider', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe('Archived');
    });

    it('wraps the label element with a tooltip', () => {
      const tooltip = getBinding(findCheckboxFilterLabel().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Include search results from archived projects');
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
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe('Archived');
    });

    it('wraps the label element with a tooltip', () => {
      const tooltip = getBinding(findCheckboxFilterLabel().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe('Include search results from archived projects');
    });
  });

  describe.each`
    include_archived | checkboxState
    ${''}            | ${'false'}
    ${'false'}       | ${'false'}
    ${'true'}        | ${'true'}
    ${'sdfsdf'}      | ${'false'}
  `('selectedFilter', ({ include_archived, checkboxState }) => {
    beforeEach(() => {
      createComponent({ urlQuery: { include_archived } });
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
        key: 'include_archived',
        value: 'false',
      });
      expect(selectedFilter).toEqual([false]);
    });
  });
});
