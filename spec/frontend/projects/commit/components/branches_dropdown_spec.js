import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';

Vue.use(Vuex);

describe('BranchesDropdown', () => {
  let wrapper;
  let store;
  const spyFetchBranches = jest.fn();

  const createComponent = (props, state = { isFetching: false }) => {
    store = new Vuex.Store({
      getters: {
        joinedBranches: () => ['_main_', '_branch_1_', '_branch_2_'],
      },
      actions: {
        fetchBranches: spyFetchBranches,
      },
      state,
    });

    wrapper = extendedWrapper(
      shallowMount(BranchesDropdown, {
        store,
        propsData: {
          value: props.value,
          blanked: props.blanked || false,
        },
      }),
    );
  };
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    spyFetchBranches.mockReset();
  });

  describe('On mount', () => {
    beforeEach(() => {
      createComponent({ value: '' });
    });

    it('invokes fetchBranches', () => {
      expect(spyFetchBranches).toHaveBeenCalled();
    });
  });

  describe('When searching', () => {
    beforeEach(() => {
      createComponent({ value: '' });
    });

    it('invokes fetchBranches', async () => {
      const spy = jest.spyOn(wrapper.vm, 'fetchBranches');

      findDropdown().vm.$emit('search', '_anything_');

      await nextTick();

      expect(spy).toHaveBeenCalledWith('_anything_');
      expect(wrapper.vm.searchTerm).toBe('_anything_');
    });
  });

  describe('Case insensitive for search term', () => {
    beforeEach(() => {
      createComponent({ value: '_BrAnCh_1_' });
    });

    it('returns only the branch searched for', () => {
      expect(findDropdown().props('items')).toEqual([{ text: '_branch_1_', value: '_branch_1_' }]);
    });
  });
});
