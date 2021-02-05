import Vuex from 'vuex';
import { GlSorting, GlSortingItem, GlFilteredSearch } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from '~/packages/list/components/package_search.vue';
import PackageTypeToken from '~/packages/list/components/tokens/package_type_token.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Package Search', () => {
  let wrapper;
  let store;
  let sorting;
  let sortingItems;

  const findPackageListSorting = () => wrapper.find(GlSorting);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);
  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);

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
        GlSortingItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('searching', () => {
    it('has a filtered-search component', () => {
      mountComponent();

      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('binds the correct props to filtered-search', () => {
      mountComponent();

      expect(findFilteredSearch().props()).toMatchObject({
        value: [],
        placeholder: 'Filter results',
        availableTokens: wrapper.vm.tokens,
      });
    });

    it('updates vuex when value changes', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('input', ['foo']);

      expect(store.dispatch).toHaveBeenCalledWith('setFilter', ['foo']);
    });

    it('emits filter:changed on submit event', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('submit');
      expect(wrapper.emitted('filter:changed')).toEqual([[]]);
    });

    it('emits filter:changed on clear event and reset vuex', () => {
      mountComponent();

      findFilteredSearch().vm.$emit('clear');

      expect(store.dispatch).toHaveBeenCalledWith('setFilter', []);
      expect(wrapper.emitted('filter:changed')).toEqual([[]]);
    });

    it('has a PackageTypeToken token', () => {
      mountComponent();

      expect(findFilteredSearch().props('availableTokens')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ token: PackageTypeToken, type: 'type', icon: 'package' }),
        ]),
      );
    });
  });

  describe('sorting', () => {
    describe('when is in projects', () => {
      beforeEach(() => {
        mountComponent();
        sorting = findPackageListSorting();
        sortingItems = findSortingItems();
      });

      it('has all the sortable items', () => {
        expect(sortingItems).toHaveLength(wrapper.vm.sortableFields.length);
      });

      it('on sort change set sorting in vuex and emit event', () => {
        sorting.vm.$emit('sortDirectionChange');
        expect(store.dispatch).toHaveBeenCalledWith('setSorting', { sort: 'asc' });
        expect(wrapper.emitted('sort:changed')).toBeTruthy();
      });

      it('on sort item click set sorting and emit event', () => {
        const item = sortingItems.at(0);
        const { orderBy } = wrapper.vm.sortableFields[0];
        item.vm.$emit('click');
        expect(store.dispatch).toHaveBeenCalledWith('setSorting', { orderBy });
        expect(wrapper.emitted('sort:changed')).toBeTruthy();
      });
    });

    describe('when is in group', () => {
      beforeEach(() => {
        mountComponent(true);
        sorting = findPackageListSorting();
        sortingItems = findSortingItems();
      });

      it('has all the sortable items', () => {
        expect(sortingItems).toHaveLength(wrapper.vm.sortableFields.length);
      });
    });
  });
});
