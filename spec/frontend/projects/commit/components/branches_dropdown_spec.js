import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';

Vue.use(Vuex);

describe('BranchesDropdown', () => {
  let wrapper;
  let store;
  const spyFetchBranches = jest.fn();

  const createComponent = (props, state = { isFetching: false, branch: '_main_' }) => {
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

  beforeEach(() => {
    createComponent({ value: '' });
  });

  afterEach(() => {
    spyFetchBranches.mockReset();
  });

  describe('On mount', () => {
    it('invokes fetchBranches', () => {
      expect(spyFetchBranches).toHaveBeenCalled();
    });
  });

  describe('Value prop changes in parent component', () => {
    it('triggers fetchBranches call', async () => {
      await wrapper.setProps({ value: 'new value' });

      expect(spyFetchBranches).toHaveBeenCalled();
    });
  });

  describe('Selecting Dropdown Item', () => {
    it('emits event', () => {
      findDropdown().vm.$emit('select', '_anything_');

      expect(wrapper.emitted()).toHaveProperty('input');
    });
  });

  describe('When searching', () => {
    it('invokes fetchBranches', async () => {
      findDropdown().vm.$emit('search', '_anything_');

      await nextTick();

      expect(spyFetchBranches).toHaveBeenCalledWith(expect.any(Object), '_anything_');
    });
  });
});
