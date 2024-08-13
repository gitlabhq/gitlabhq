import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Item from '~/ide/components/branches/item.vue';
import List from '~/ide/components/branches/search_list.vue';
import { branches } from '../../mock_data';

Vue.use(Vuex);

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
      store: fakeStore,
    });
  };

  it('calls fetch on mounted', () => {
    createComponent();
    expect(fetchBranchesMock).toHaveBeenCalled();
  });

  it('renders loading icon when `isLoading` is true', () => {
    createComponent({ isLoading: true });
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders branches not found when search is not empty and branches list is empty', async () => {
    createComponent({ branches: [] });
    wrapper.find('input[type="search"]').setValue('something');

    await nextTick();
    expect(wrapper.text()).toContain('No branches found');
  });

  describe('with branches', () => {
    it('renders list', () => {
      createComponent({ branches });
      const items = wrapper.findAllComponents(Item);

      expect(items.length).toBe(branches.length);
    });

    it('renders check next to active branch', () => {
      const activeBranch = 'regular';
      createComponent({ branches }, activeBranch);
      const items = wrapper.findAllComponents(Item).filter((w) => w.props('isActive'));

      expect(items.length).toBe(1);
      expect(items.at(0).props('item').name).toBe(activeBranch);
    });
  });
});
