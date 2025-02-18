import { GlCollapsibleListbox, GlListboxItem, GlIcon, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { mockSourceBranches } from 'jest/search/mock_data';

describe('BranchDropdown', () => {
  let wrapper;

  const defaultProps = {
    listData: mockSourceBranches,
    error: '',
    selectedItem: 'Master Item',
    headerText: 'Filter header',
    searchText: 'Search filter items',
    selectedBranch: 'Master Item',
    icon: 'work',
    isLoading: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(FilterDropdown, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
        GlIcon,
      },
    });
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlListboxItems = () => wrapper.findAllComponents(GlListboxItem);
  const findGlAvatar = () => wrapper.findAllComponents(GlAvatar);
  const findErrorMessage = () => wrapper.findByTestId('branch-dropdown-error');

  describe('when nothing is selected', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the GlCollapsibleListbox component with correct props', () => {
      const toggleClass = [
        {
          '!gl-shadow-inner-1-red-500': false,
          'gl-font-monospace': true,
        },
        'gl-mb-0',
      ];

      // This is a workaround for "Property or method `nodeType` is not defined"
      // https://docs.gitlab.com/ee/development/fe_guide/troubleshooting.html#property-or-method-nodetype-is-not-defined-but-youre-not-using-nodetype-anywhere
      // usual workourounds didn't work so I had to do following:

      const props = findGlCollapsibleListbox().props();

      expect(props.selected).toBe('Master Item');
      expect(props.headerText).toBe('Filter header');
      expect(props.items).toMatchObject(mockSourceBranches);
      expect(props.noResultsText).toBe('No results found');
      expect(props.searching).toBe(false);
      expect(props.searchPlaceholder).toBe('Search filter items');
      expect(props.toggleClass).toMatchObject(toggleClass);
      expect(props.toggleText).toBe('Search filter items');
      expect(props.icon).toBe('work');
      expect(props.loading).toBe(false);
      expect(props.resetButtonLabel).toBe('Reset');
    });

    it('renders error message when error prop is passed', async () => {
      createComponent({ error: 'Error 1' });

      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe('Error 1');
    });

    it('renders error message reactivly', async () => {
      createComponent();

      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(false);

      wrapper.setProps({ error: 'Error 1' });
      await waitForPromises();
      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe('Error 1');
    });

    it('search filters items', async () => {
      findGlCollapsibleListbox().vm.$emit('search', 'fea');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
      expect(findGlListboxItems()).toHaveLength(1);
      expect(findGlAvatar()).toHaveLength(1);
    });

    it('emits hide', () => {
      findGlCollapsibleListbox().vm.$emit('hidden');

      expect(wrapper.emitted('hide')).toStrictEqual([[]]);
    });

    it('emits selected', () => {
      findGlCollapsibleListbox().vm.$emit('select', 'main');

      expect(wrapper.emitted('selected')).toStrictEqual([['main']]);
    });

    it('emits reset', () => {
      findGlCollapsibleListbox().vm.$emit('reset');

      expect(wrapper.emitted('reset')).toStrictEqual([[]]);
    });

    it('emits hide and selected if there are no results but query contains strings', async () => {
      findGlCollapsibleListbox().vm.$emit('search', 'ttteeeeessssssttttt');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();

      expect(findGlListboxItems()).toHaveLength(0);

      findGlCollapsibleListbox().vm.$emit('hidden');

      expect(wrapper.emitted('hide')).toStrictEqual([[]]);
      expect(wrapper.emitted('selected')).toStrictEqual([['ttteeeeessssssttttt']]);
    });
  });
});
