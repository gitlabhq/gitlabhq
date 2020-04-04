import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import List from '~/ide/components/branches/search_list.vue';
import Item from '~/ide/components/branches/item.vue';
import { branches } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE branches search list', () => {
  let wrapper;
  const fetchBranchesMock = jest.fn();

  const createComponent = (state, currentBranchId = 'branch') => {
    const fakeStore = new Vuex.Store({
      state: {
        currentBranchId,
        currentProjectId: 'project',
      },
      modules: {
        branches: {
          namespaced: true,
          state: { isLoading: false, branches: [], ...state },
          actions: {
            fetchBranches: fetchBranchesMock,
          },
        },
      },
    });

    wrapper = shallowMount(List, {
      localVue,
      store: fakeStore,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('calls fetch on mounted', () => {
    createComponent();
    expect(fetchBranchesMock).toHaveBeenCalled();
  });

  it('renders loading icon when `isLoading` is true', () => {
    createComponent({ isLoading: true });
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders branches not found when search is not empty and branches list is empty', () => {
    createComponent({ branches: [] });
    wrapper.find('input[type="search"]').setValue('something');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.text()).toContain(__('No branches found'));
    });
  });

  describe('with branches', () => {
    it('renders list', () => {
      createComponent({ branches });
      const items = wrapper.findAll(Item);

      expect(items.length).toBe(branches.length);
    });

    it('renders check next to active branch', () => {
      const activeBranch = 'regular';
      createComponent({ branches }, activeBranch);
      const items = wrapper.findAll(Item).filter(w => w.props('isActive'));

      expect(items.length).toBe(1);
      expect(items.at(0).props('item').name).toBe(activeBranch);
    });
  });
});
