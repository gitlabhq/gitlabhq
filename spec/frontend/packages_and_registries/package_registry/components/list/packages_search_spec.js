import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sortableFields } from '~/packages_and_registries/package_registry/utils';
import component from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import PackageTypeToken from '~/packages_and_registries/package_registry/components/list/tokens/package_type_token.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { LIST_KEY_CREATED_AT } from '~/packages_and_registries/package_registry/constants';

import { getQueryParams, extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import { TOKEN_TYPE_TYPE } from '~/vue_shared/components/filtered_search_bar/constants';

jest.mock('~/packages_and_registries/shared/utils');

useMockLocationHelper();

describe('Package Search', () => {
  let wrapper;

  const defaultQueryParamsMock = {
    filters: ['foo'],
    sorting: { sort: 'desc' },
  };

  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mountComponent = (isGroupPage = false) => {
    wrapper = shallowMountExtended(component, {
      provide() {
        return {
          isGroupPage,
        };
      },
      stubs: {
        UrlSync,
        LocalStorageSync,
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

  it('has a LocalStorageSync component', () => {
    mountComponent();

    expect(findLocalStorageSync().props()).toMatchObject({
      storageKey: 'package_registry_list_sorting',
      value: {
        orderBy: LIST_KEY_CREATED_AT,
        sort: 'desc',
      },
    });
  });

  it.each`
    isGroupPage | page
    ${false}    | ${'project'}
    ${true}     | ${'group'}
  `('in a $page page binds the right props', async ({ isGroupPage }) => {
    mountComponent(isGroupPage);

    await nextTick();

    expect(findRegistrySearch().props()).toMatchObject({
      tokens: expect.arrayContaining([
        expect.objectContaining({
          token: PackageTypeToken,
          type: TOKEN_TYPE_TYPE,
          icon: 'package',
        }),
      ]),
      sortableFields: sortableFields(isGroupPage),
    });
  });

  it('on sorting:changed emits update event and update internal sort', async () => {
    const payload = { sort: 'foo' };

    mountComponent();

    await nextTick();

    findRegistrySearch().vm.$emit('sorting:changed', payload);

    await nextTick();

    expect(findRegistrySearch().props('sorting')).toEqual({ sort: 'foo', orderBy: 'created_at' });

    // there is always a first call on mounted that emits up default values
    expect(wrapper.emitted('update')[1]).toEqual([
      {
        filters: {
          packageName: '',
          packageType: undefined,
        },
        sort: 'CREATED_FOO',
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
        filters: {
          packageName: '',
          packageType: undefined,
        },
        sort: 'CREATED_DESC',
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
