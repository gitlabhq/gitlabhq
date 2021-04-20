import { GlSorting, GlSortingItem } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ReleasesSort from '~/releases/components/releases_sort.vue';
import createStore from '~/releases/stores';
import createIndexModule from '~/releases/stores/modules/index';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/releases/components/releases_sort.vue', () => {
  let wrapper;
  let store;
  let indexModule;
  const projectId = 8;

  const createComponent = () => {
    indexModule = createIndexModule({ projectId });

    store = createStore({
      modules: {
        index: indexModule,
      },
    });

    store.dispatch = jest.fn();

    wrapper = shallowMount(ReleasesSort, {
      store,
      stubs: {
        GlSortingItem,
      },
      localVue,
    });
  };

  const findReleasesSorting = () => wrapper.find(GlSorting);
  const findSortingItems = () => wrapper.findAll(GlSortingItem);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('has all the sortable items', () => {
    expect(findSortingItems()).toHaveLength(wrapper.vm.sortOptions.length);
  });

  it('on sort change set sorting in vuex and emit event', () => {
    findReleasesSorting().vm.$emit('sortDirectionChange');
    expect(store.dispatch).toHaveBeenCalledWith('index/setSorting', { sort: 'asc' });
    expect(wrapper.emitted('sort:changed')).toBeTruthy();
  });

  it('on sort item click set sorting and emit event', () => {
    const item = findSortingItems().at(0);
    const { orderBy } = wrapper.vm.sortOptions[0];
    item.vm.$emit('click');
    expect(store.dispatch).toHaveBeenCalledWith('index/setSorting', { orderBy });
    expect(wrapper.emitted('sort:changed')).toBeTruthy();
  });
});
