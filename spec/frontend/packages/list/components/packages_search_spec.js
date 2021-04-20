import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import component from '~/packages/list/components/package_search.vue';
import PackageTypeToken from '~/packages/list/components/tokens/package_type_token.vue';
import { sortableFields } from '~/packages/list/utils';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Package Search', () => {
  let wrapper;
  let store;

  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const createStore = (isGroupPage) => {
    const state = {
      config: {
        isGroupPage,
      },
      sorting: {
        orderBy: 'version',
        sort: 'desc',
      },
      filter: [],
    };
    store = new Vuex.Store({
      state,
    });
    store.dispatch = jest.fn();
  };

  const mountComponent = (isGroupPage = false) => {
    createStore(isGroupPage);

    wrapper = shallowMount(component, {
      localVue,
      store,
      stubs: {
        UrlSync,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('has a registry search component', () => {
    mountComponent();

    expect(findRegistrySearch().exists()).toBe(true);
    expect(findRegistrySearch().props()).toMatchObject({
      filter: store.state.filter,
      sorting: store.state.sorting,
      tokens: expect.arrayContaining([
        expect.objectContaining({ token: PackageTypeToken, type: 'type', icon: 'package' }),
      ]),
      sortableFields: sortableFields(),
    });
  });

  it.each`
    isGroupPage | page
    ${false}    | ${'project'}
    ${true}     | ${'group'}
  `('in a $page page binds the right props', ({ isGroupPage }) => {
    mountComponent(isGroupPage);

    expect(findRegistrySearch().props()).toMatchObject({
      filter: store.state.filter,
      sorting: store.state.sorting,
      tokens: expect.arrayContaining([
        expect.objectContaining({ token: PackageTypeToken, type: 'type', icon: 'package' }),
      ]),
      sortableFields: sortableFields(isGroupPage),
    });
  });

  it('on sorting:changed emits update event and calls vuex setSorting', () => {
    const payload = { sort: 'foo' };

    mountComponent();

    findRegistrySearch().vm.$emit('sorting:changed', payload);

    expect(store.dispatch).toHaveBeenCalledWith('setSorting', payload);
    expect(wrapper.emitted('update')).toEqual([[]]);
  });

  it('on filter:changed calls vuex setFilter', () => {
    const payload = ['foo'];

    mountComponent();

    findRegistrySearch().vm.$emit('filter:changed', payload);

    expect(store.dispatch).toHaveBeenCalledWith('setFilter', payload);
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
