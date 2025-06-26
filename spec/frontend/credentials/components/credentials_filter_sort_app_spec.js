import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CredentialsFilterSortApp from '~/credentials/components/credentials_filter_sort_app.vue';
import { goTo } from '~/credentials/utils';

jest.mock('~/credentials/utils', () => ({
  ...jest.requireActual('~/credentials/utils'),
  initializeValuesFromQuery: () => ({
    sorting: { value: 'expires', isAsc: true },
    tokens: [],
  }),
  goTo: jest.fn(),
}));

describe('CredentialsFilterSortApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CredentialsFilterSortApp);
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findSorting = () => wrapper.findComponent(GlSorting);

  it('reloads the page with correct parameters when the search is submitted', () => {
    createComponent();
    findFilteredSearch().vm.$emit('submit', [
      { type: 'search', value: { data: '', operator: '=' } },
    ]);

    expect(goTo).toHaveBeenCalledWith('expires', true, [
      { type: 'search', value: { data: '', operator: '=' } },
    ]);
  });

  it('reloads the page with correct parameters when sorting is changed', () => {
    createComponent();
    findSorting().vm.$emit('sortByChange', 'name');

    expect(goTo).toHaveBeenCalledWith('name', true, []);
  });

  it('reloads the page with correct parameters when sorting direction is changed', () => {
    createComponent();
    findSorting().vm.$emit('sortDirectionChange', false);

    expect(goTo).toHaveBeenCalledWith('expires', false, []);
  });

  it('removes all tokens if ssh or gpg keys are chosen', async () => {
    createComponent();
    const filteredSearch = findFilteredSearch();
    filteredSearch.vm.$emit('input', [
      { type: 'search', value: { data: 'my search', operator: '=' } },
      { type: 'filter', value: { data: 'personal_access_tokens', operator: '=' } },
    ]);
    await nextTick();

    expect(findFilteredSearch().props('value')).toMatchObject([
      { type: 'search', value: { data: 'my search', operator: '=' } },
      { type: 'filter', value: { data: 'personal_access_tokens', operator: '=' } },
    ]);

    filteredSearch.vm.$emit('input', [
      { type: 'search', value: { data: 'my search', operator: '=' } },
      { type: 'filter', value: { data: 'ssh_keys', operator: '=' } },
    ]);
    await nextTick();

    expect(findFilteredSearch().props('value')).toMatchObject([
      { type: 'filter', value: { data: 'ssh_keys', operator: '=' } },
    ]);
  });

  it('shows owner_type token only when personal access tokens is selected', async () => {
    createComponent();
    const filteredSearch = findFilteredSearch();

    // Initially, without any filter, owner_type should not be available (6 tokens: filter + 5 base tokens)
    expect(filteredSearch.props('availableTokens')).toHaveLength(6);
    expect(
      filteredSearch.props('availableTokens').some((token) => token.type === 'owner_type'),
    ).toBe(false);

    // When personal_access_tokens is selected, owner_type should be available (7 tokens)
    filteredSearch.vm.$emit('input', [
      { type: 'filter', value: { data: 'personal_access_tokens', operator: '=' } },
    ]);
    await nextTick();

    expect(filteredSearch.props('availableTokens')).toHaveLength(7);
    expect(
      filteredSearch.props('availableTokens').some((token) => token.type === 'owner_type'),
    ).toBe(true);
  });

  it('removes owner_type tokens when switching away from personal access tokens', async () => {
    createComponent();
    const filteredSearch = findFilteredSearch();

    // Start with personal access tokens and owner_type filter
    filteredSearch.vm.$emit('input', [
      { type: 'filter', value: { data: 'personal_access_tokens', operator: '=' } },
      { type: 'owner_type', value: { data: 'human', operator: '=' } },
    ]);
    await nextTick();

    expect(findFilteredSearch().props('value')).toHaveLength(2);

    // Switch to resource access tokens - should remove owner_type token
    filteredSearch.vm.$emit('input', [
      { type: 'filter', value: { data: 'resource_access_tokens', operator: '=' } },
      { type: 'owner_type', value: { data: 'human', operator: '=' } },
    ]);
    await nextTick();

    expect(findFilteredSearch().props('value')).toHaveLength(1);
    expect(findFilteredSearch().props('value')[0].type).toBe('filter');
    expect(findFilteredSearch().props('value')[0].value.data).toBe('resource_access_tokens');
  });

  it('removes all available tokens if ssh or gpg keys are chosen', async () => {
    createComponent();
    const filteredSearch = findFilteredSearch();
    expect(filteredSearch.props('availableTokens')).toHaveLength(6);

    filteredSearch.vm.$emit('input', [
      { type: 'filter', value: { data: 'ssh_keys', operator: '=' } },
    ]);
    await nextTick();

    expect(filteredSearch.props('availableTokens')).toHaveLength(1);
  });

  it('hides sorting if ssh or gpg keys are chosen', async () => {
    createComponent();
    const sorting = findSorting();
    expect(sorting.exists()).toBe(true);
    findFilteredSearch().vm.$emit('input', [
      { type: 'filter', value: { data: 'ssh_keys', operator: '=' } },
    ]);
    await nextTick();

    expect(sorting.exists()).toBe(false);
  });
});
