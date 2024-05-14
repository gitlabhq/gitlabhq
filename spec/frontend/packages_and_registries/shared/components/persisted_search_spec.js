import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import component from '~/packages_and_registries/shared/components/persisted_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import {
  getQueryParams,
  extractFilterAndSorting,
  extractPageInfo,
} from '~/packages_and_registries/shared/utils';

jest.mock('~/packages_and_registries/shared/utils');

Vue.use(VueRouter);

describe('Persisted Search', () => {
  let router;
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
    router = new VueRouter({ mode: 'history' });

    wrapper = shallowMountExtended(component, {
      propsData,
      router,
      stubs: {
        UrlSync,
      },
    });
  };

  beforeEach(() => {
    extractFilterAndSorting.mockReturnValue(defaultQueryParamsMock);
    extractPageInfo.mockReturnValue({
      after: '123',
      before: null,
    });
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

  it('emits update event on mount', () => {
    mountComponent();

    expect(wrapper.emitted('update')[0]).toEqual([
      {
        filters: ['foo'],
        sort: 'TEST_DESC',
        pageInfo: {
          after: '123',
          before: null,
        },
        sorting: defaultQueryParamsMock.sorting,
      },
    ]);
  });

  it('re-emits update event when url-sync emits popstate event', () => {
    mountComponent();

    extractFilterAndSorting.mockReturnValue({
      filters: [],
      sorting: {},
    });
    extractPageInfo.mockReturnValue({
      after: null,
      before: '456',
    });

    findUrlSync().vm.$emit('popstate');

    // there is always a first call on mounted that emits up default values
    expect(wrapper.emitted('update')[1]).toEqual([
      {
        filters: [],
        sort: 'TEST_DESC',
        sorting: defaultQueryParamsMock.sorting,
        pageInfo: {
          before: '456',
          after: null,
        },
      },
    ]);
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
        pageInfo: {},
        sorting: payload,
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
        pageInfo: {
          after: '123',
          before: null,
        },
        sorting: defaultQueryParamsMock.sorting,
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

  it('sets the component sorting, filtering and page info based on the querystring', async () => {
    mountComponent();

    await nextTick();

    expect(getQueryParams).toHaveBeenCalled();

    expect(findRegistrySearch().props()).toMatchObject({
      filters: defaultQueryParamsMock.filters,
      sorting: defaultQueryParamsMock.sorting,
    });
  });
});
