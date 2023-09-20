import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sortableFields } from '~/packages_and_registries/package_registry/utils';
import component from '~/packages_and_registries/package_registry/components/list/package_search.vue';
import PackageTypeToken from '~/packages_and_registries/package_registry/components/list/tokens/package_type_token.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import { LIST_KEY_CREATED_AT } from '~/packages_and_registries/package_registry/constants';

import { TOKEN_TYPE_TYPE } from '~/vue_shared/components/filtered_search_bar/constants';

describe('Package Search', () => {
  let wrapper;

  const defaultQueryParamsMock = {
    filters: ['foo'],
    sorting: { sort: 'desc' },
  };

  const findPersistedSearch = () => wrapper.findComponent(PersistedSearch);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const mountComponent = (isGroupPage = false) => {
    wrapper = shallowMountExtended(component, {
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

    expect(findPersistedSearch().props()).toMatchObject({
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
        filters: {
          packageName: '',
          packageType: undefined,
        },
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
        },
        sort: payload.sort,
        sorting: payload.sorting,
      },
    ]);
  });
});
