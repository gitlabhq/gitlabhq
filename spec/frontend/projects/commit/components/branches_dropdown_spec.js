import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue, { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';
import { useCherryPickCommit } from '~/projects/commit/store/cherry_pick_commit';

Vue.use(PiniaVuePlugin);

describe('BranchesDropdown', () => {
  let wrapper;
  let pinia;
  let store;

  const createComponent = (props, state = { isFetching: false, branch: '_main_' }) => {
    pinia = createTestingPinia();
    store = useCherryPickCommit();
    store.$patch({ branches: ['_main_', '_branch_1_', '_branch_2_'], ...state });

    wrapper = extendedWrapper(
      shallowMount(BranchesDropdown, {
        pinia,
        provide: {
          modalStore: store,
        },
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

  describe('On mount', () => {
    it('invokes fetchBranches', () => {
      expect(store.fetchBranches).toHaveBeenCalled();
    });
  });

  describe('Value prop changes in parent component', () => {
    it('triggers fetchBranches call', async () => {
      await wrapper.setProps({ value: 'new value' });

      expect(store.fetchBranches).toHaveBeenCalled();
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

      expect(store.fetchBranches).toHaveBeenCalledWith('_anything_');
    });
  });
});
