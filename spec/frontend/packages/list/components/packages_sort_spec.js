import Vuex from 'vuex';
import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import PackagesSort from '~/packages/list/components/packages_sort.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_sort', () => {
  let wrapper;
  let store;
  let sorting;
  let sortingItems;

  const findPackageListSorting = () => wrapper.find(GlSorting);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);

  const createStore = isGroupPage => {
    const state = {
      config: {
        isGroupPage,
      },
      sorting: {
        orderBy: 'version',
        sort: 'desc',
      },
    };
    store = new Vuex.Store({
      state,
    });
    store.dispatch = jest.fn();
  };

  const mountComponent = (isGroupPage = false) => {
    createStore(isGroupPage);

    wrapper = mount(PackagesSort, {
      localVue,
      store,
      stubs: {
        ...stubChildren(PackagesSort),
        GlSortingItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
