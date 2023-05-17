import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import component from '~/packages_and_registries/shared/components/persisted_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';

jest.mock('~/packages_and_registries/shared/utils');

useMockLocationHelper();

describe('Persisted Search', () => {
  let wrapper;

  const defaultQueryParamsMock = {
    filters: ['foo'],
    sorting: { sort: 'desc', orderBy: 'test' },
  };

  const defaultProps = {
    sortableFields: [
      { orderBy: 'test', label: 'test' },
      { orderBy: 'foo', label: 'foo' },
    ],
    defaultOrder: 'test',
    defaultSort: 'asc',
  };

  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(component, {
      propsData,
      stubs: {
        UrlSync,
      },
    });
  };

  beforeEach(() => {
    extractFilterAndSorting.mockReturnValue(defaultQueryParamsMock);
  });

  it('has a registry search component', async () => {
    mountComponent();

    await nextTick();

    expect(findRegistrySearch().exists()).toBe(true);
  });

  it('registry search is mounted after mount', () => {
    mountComponent();

    expect(findRegistrySearch().exists()).toBe(false);
  });

  it('has a UrlSync component', () => {
    mountComponent();

    expect(findUrlSync().exists()).toBe(true);
  });

  it('on sorting:changed emits update event and update internal sort', async () => {
    const payload = { sort: 'desc', orderBy: 'test' };

    mountComponent();

    await nextTick();

    findRegistrySearch().vm.$emit('sorting:changed', payload);

    await nextTick();

    expect(findRegistrySearch().props('sorting')).toMatchObject(payload);

    // there is always a first call on mounted that emits up default values
    expect(wrapper.emitted('update')[1]).toEqual([
      {
        filters: ['foo'],
        sort: 'TEST_DESC',
      },
    ]);
  });

  it('on filter:changed updates the filters', async () => {
    const payload = ['foo'];

    mountComponent();

    await nextTick();

    findRegistrySearch().vm.$emit('filter:changed', payload);

    await nextTick();

    expect(findRegistrySearch().props('filters')).toEqual(['foo']);
  });

  it('on filter:submit emits update event', async () => {
    mountComponent();

    await nextTick();

    findRegistrySearch().vm.$emit('filter:submit');

    expect(wrapper.emitted('update')[1]).toEqual([
      {
        filters: ['foo'],
        sort: 'TEST_DESC',
      },
    ]);
  });

  it('on query:changed calls updateQuery from UrlSync', async () => {
    jest.spyOn(UrlSync.methods, 'updateQuery').mockImplementation(() => {});

    mountComponent();

    await nextTick();

    findRegistrySearch().vm.$emit('query:changed');

    expect(UrlSync.methods.updateQuery).toHaveBeenCalled();
  });

  it('sets the component sorting and filtering based on the querystring', async () => {
    mountComponent();

    await nextTick();

    expect(getQueryParams).toHaveBeenCalled();

    expect(findRegistrySearch().props()).toMatchObject({
      filters: defaultQueryParamsMock.filters,
      sorting: defaultQueryParamsMock.sorting,
    });
  });
});
