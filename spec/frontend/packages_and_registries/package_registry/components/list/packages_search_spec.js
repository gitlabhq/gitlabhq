import { nextTick } from 'vue';
import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sortableFields } from '~/packages_and_registries/package_registry/utils';
import PackageSearch from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import { LIST_KEY_CREATED_AT } from '~/packages_and_registries/package_registry/constants';

import {
  OPERATORS_IS,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_VERSION,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';

describe('Package Search', () => {
  let wrapper;

  const defaultQueryParamsMock = {
    filters: ['foo'],
    sorting: { sort: 'desc' },
  };

  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mountComponent = (isGroupPage = false) => {
    wrapper = shallowMountExtended(PackageSearch, {
      provide() {
        return {
          isGroupPage,
        };
      },
      stubs: {
        LocalStorageSync,
      },
    });
  };

  it('has a registry search component', async () => {
    mountComponent();

    await nextTick();

    expect(findPersistedSearch().exists()).toBe(true);
  });

  it('registry search is mounted after mount', () => {
    mountComponent();

    expect(findPersistedSearch().exists()).toBe(false);
  });

  it('has a LocalStorageSync component with project key', () => {
    mountComponent();

    expect(findLocalStorageSync().props()).toMatchObject({
      storageKey: 'package_registry_list_sorting',
      value: {
        orderBy: LIST_KEY_CREATED_AT,
        sort: 'desc',
      },
    });
  });

  it('has a LocalStorageSync component with group key', () => {
    mountComponent(true);

    expect(findLocalStorageSync().props()).toMatchObject({
      storageKey: 'group_package_registry_list_sorting',
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

    expect(findPersistedSearch().props()).toMatchObject({
      tokens: expect.arrayContaining([
        expect.objectContaining({
          token: GlFilteredSearchToken,
          type: TOKEN_TYPE_TYPE,
          icon: 'package',
          unique: true,
          operators: OPERATORS_IS,
        }),
        expect.objectContaining({
          token: GlFilteredSearchToken,
          type: TOKEN_TYPE_VERSION,
          icon: 'doc-versions',
          unique: true,
          operators: OPERATORS_IS,
        }),
        expect.objectContaining({
          type: TOKEN_TYPE_STATUS,
          icon: 'status',
          title: TOKEN_TITLE_STATUS,
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
        }),
      ]),
      sortableFields: sortableFields(isGroupPage),
    });
  });

  it('on update event re-emits update event and updates internal sort', async () => {
    const payload = {
      sort: 'CREATED_FOO',
      filters: defaultQueryParamsMock.filters,
      sorting: { sort: 'foo', orderBy: 'created_at' },
    };

    mountComponent();

    await nextTick();

    findPersistedSearch().vm.$emit('update', payload);

    await nextTick();

    expect(findLocalStorageSync().props('value')).toEqual({ sort: 'foo', orderBy: 'created_at' });

    expect(wrapper.emitted('update')[0]).toEqual([
      {
        filters: {},
        sort: payload.sort,
        sorting: payload.sorting,
      },
    ]);
  });

  it('on update event, re-emits update event with formatted filters', async () => {
    const payload = {
      sort: 'CREATED_FOO',
      filters: [
        { type: 'type', value: { data: 'Generic', operator: '=' }, id: 'token-3' },
        { type: 'version', value: { data: '1.0.1', operator: '=' }, id: 'token-6' },
        { type: 'status', value: { data: 'hidden', operator: '=' }, id: 'token-7' },
        { id: 'token-4', type: 'filtered-search-term', value: { data: 'gl' } },
        { id: 'token-5', type: 'filtered-search-term', value: { data: '' } },
      ],
      sorting: { sort: 'foo', orderBy: 'created_at' },
    };

    mountComponent();

    await nextTick();

    findPersistedSearch().vm.$emit('update', payload);

    await nextTick();

    expect(wrapper.emitted('update')[0]).toEqual([
      {
        filters: {
          packageName: 'gl',
          packageType: 'GENERIC',
          packageVersion: '1.0.1',
          packageStatus: 'HIDDEN',
        },
        sort: payload.sort,
        sorting: payload.sorting,
      },
    ]);
  });
});
