import { GlCollapsibleListbox, GlIcon, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { mockSourceBranches } from 'jest/search/mock_data';

describe('FilterDropdown', () => {
  let wrapper;

  const defaultProps = {
    listData: mockSourceBranches,
    error: '',
    selectedItem: 'Master Item',
    headerText: 'Filter header',
    searchText: 'Search filter items',
    isLoading: false,
    hasApiSearch: false,
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
        GlAvatar,
      },
    });
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findErrorMessage = () => wrapper.findByTestId('branch-dropdown-error');

  beforeEach(() => {
    createComponent();
  });

  it('renders the GlCollapsibleListbox component with correct props', () => {
    const props = findGlCollapsibleListbox().props();

    expect(props.selected).toBe('Master Item');
    expect(props.headerText).toBe('Filter header');
    expect(props.items).toMatchObject(mockSourceBranches);
    expect(props.noResultsText).toBe('No results found');
    expect(props.searching).toBe(false);
    expect(props.searchPlaceholder).toBe('Search filter items');
    expect(props.toggleClass).toBe('gl-mb-0');
    expect(props.toggleText).toBe('Search filter items');
    expect(props.loading).toBe(false);
    expect(props.resetButtonLabel).toBe('Reset');
  });

  it('renders error message when error prop is passed', async () => {
    createComponent({ error: 'Error 1' });
    await waitForPromises();

    expect(findErrorMessage().exists()).toBe(true);
    expect(findErrorMessage().text()).toBe('Error 1');
  });

  it('renders error message reactively', async () => {
    expect(findErrorMessage().exists()).toBe(false);

    wrapper.setProps({ error: 'Error 1' });
    await waitForPromises();

    expect(findErrorMessage().exists()).toBe(true);
    expect(findErrorMessage().text()).toBe('Error 1');
  });

  it('filters items using local fuzzy search', async () => {
    findGlCollapsibleListbox().vm.$emit('search', 'fea');

    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();

    expect(findGlCollapsibleListbox().props('items')).toHaveLength(1);
  });

  it('emits search event for API search', () => {
    createComponent({ hasApiSearch: true });

    findGlCollapsibleListbox().vm.$emit('search', 'api query');

    expect(wrapper.emitted('search')).toEqual([['api query']]);
  });

  it('emits hide event', () => {
    findGlCollapsibleListbox().vm.$emit('hidden');

    expect(wrapper.emitted('hide')).toEqual([[]]);
  });

  it('emits selected event', () => {
    findGlCollapsibleListbox().vm.$emit('select', 'main');

    expect(wrapper.emitted('selected')).toEqual([['main']]);
  });

  it('emits reset event', () => {
    findGlCollapsibleListbox().vm.$emit('reset');

    expect(wrapper.emitted('reset')).toEqual([[]]);
  });

  it('emits selected with query text if no local results on hide', async () => {
    findGlCollapsibleListbox().vm.$emit('search', 'noresultquery');

    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    await waitForPromises();

    wrapper.findComponent(GlCollapsibleListbox).vm.$emit('hidden');

    expect(wrapper.emitted('selected')).toEqual([['noresultquery']]);
    expect(wrapper.emitted('hide')).toEqual([[]]);
  });
});
