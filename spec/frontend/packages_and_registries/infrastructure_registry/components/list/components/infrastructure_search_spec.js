import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue from 'vue';
import component from '~/packages_and_registries/infrastructure_registry/list/components/infrastructure_search.vue';
import { useInfrastructureList } from '~/packages_and_registries/infrastructure_registry/list/stores';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

Vue.use(PiniaVuePlugin);

describe('Infrastructure Search', () => {
  let wrapper;
  let pinia;
  let store;

  const sortableFields = () => [
    { orderBy: 'name', label: 'Name' },
    { orderBy: 'version', label: 'Version' },
    { orderBy: 'created_at', label: 'Published' },
  ];

  const groupSortableFields = () => [
    { orderBy: 'name', label: 'Name' },
    { orderBy: 'project_path', label: 'Project' },
    { orderBy: 'version', label: 'Version' },
    { orderBy: 'created_at', label: 'Published' },
  ];

  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const createStore = () => {
    pinia = createTestingPinia();
    store = useInfrastructureList();
    store.$patch({
      sorting: { orderBy: 'version', sort: 'desc' },
      filter: [],
    });
  };

  const mountComponent = (isGroupPage = false) => {
    createStore();

    wrapper = shallowMount(component, {
      pinia,
      provide: {
        isGroupPage,
      },
      stubs: {
        UrlSync,
      },
    });
  };

  it('has a registry search component', () => {
    mountComponent();

    expect(findRegistrySearch().exists()).toBe(true);
    expect(findRegistrySearch().props()).toMatchObject({
      filters: store.filter,
      sorting: store.sorting,
      tokens: [],
      sortableFields: sortableFields(),
    });
  });

  it.each`
    isGroupPage | page         | fields
    ${false}    | ${'project'} | ${sortableFields()}
    ${true}     | ${'group'}   | ${groupSortableFields()}
  `('in a $page page binds the right props', ({ isGroupPage, fields }) => {
    mountComponent(isGroupPage);

    expect(findRegistrySearch().props()).toMatchObject({
      filters: store.filter,
      sorting: store.sorting,
      tokens: [],
      sortableFields: fields,
    });
  });

  it('on sorting:changed emits update event and calls setSorting', () => {
    const payload = { sort: 'foo' };

    mountComponent();

    findRegistrySearch().vm.$emit('sorting:changed', payload);

    expect(store.setSorting).toHaveBeenCalledWith(payload);
    expect(wrapper.emitted('update')).toEqual([[]]);
  });

  it('on filter:changed calls setFilter', () => {
    const payload = ['foo'];

    mountComponent();

    findRegistrySearch().vm.$emit('filter:changed', payload);

    expect(store.setFilter).toHaveBeenCalledWith(payload);
  });

  it('on filter:submit emits update event', () => {
    mountComponent();

    findRegistrySearch().vm.$emit('filter:submit');

    expect(wrapper.emitted('update')).toEqual([[]]);
  });

  it('has a UrlSync component', () => {
    mountComponent();

    expect(findUrlSync().exists()).toBe(true);
  });

  it('on query:changed calls updateQuery from UrlSync', () => {
    jest.spyOn(UrlSync.methods, 'updateQuery').mockImplementation(() => {});

    mountComponent();

    findRegistrySearch().vm.$emit('query:changed');

    expect(UrlSync.methods.updateQuery).toHaveBeenCalled();
  });
});
