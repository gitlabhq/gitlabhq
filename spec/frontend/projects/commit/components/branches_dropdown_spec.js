import { GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';

Vue.use(Vuex);

describe('BranchesDropdown', () => {
  let wrapper;
  let store;
  const spyFetchBranches = jest.fn();

  const createComponent = (term, state = { isFetching: false }) => {
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
          value: term,
        },
      }),
    );
  };

  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownItemByIndex = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findNoResults = () => wrapper.findByTestId('empty-result-message');
  const findLoading = () => wrapper.findByTestId('dropdown-text-loading-icon');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    spyFetchBranches.mockReset();
  });

  describe('On mount', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('invokes fetchBranches', () => {
      expect(spyFetchBranches).toHaveBeenCalled();
    });
  });

  describe('Loading states', () => {
    it('shows loading icon while fetching', () => {
      createComponent('', { isFetching: true });

      expect(findLoading().isVisible()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent('');

      expect(findLoading().isVisible()).toBe(false);
    });
  });

  describe('No branches found', () => {
    beforeEach(() => {
      createComponent('_non_existent_branch_');
    });

    it('renders empty results message', () => {
      expect(findNoResults().text()).toBe('No matching results');
    });

    it('shows GlSearchBoxByType with default attributes', () => {
      expect(findSearchBoxByType().exists()).toBe(true);
      expect(findSearchBoxByType().vm.$attrs).toMatchObject({
        placeholder: 'Search branches',
        debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      });
    });
  });

  describe('Search term is empty', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('renders all branches when search term is empty', () => {
      expect(findAllDropdownItems()).toHaveLength(3);
      expect(findDropdownItemByIndex(0).text()).toBe('_main_');
      expect(findDropdownItemByIndex(1).text()).toBe('_branch_1_');
      expect(findDropdownItemByIndex(2).text()).toBe('_branch_2_');
    });

    it('should not be selected on the inactive branch', () => {
      expect(wrapper.vm.isSelected('_main_')).toBe(false);
    });
  });

  describe('When searching', () => {
    beforeEach(() => {
      createComponent('');
    });

    it('invokes fetchBranches', async () => {
      const spy = jest.spyOn(wrapper.vm, 'fetchBranches');

      findSearchBoxByType().vm.$emit('input', '_anything_');

      await wrapper.vm.$nextTick();

      expect(spy).toHaveBeenCalledWith('_anything_');
      expect(wrapper.vm.searchTerm).toBe('_anything_');
    });
  });

  describe('Branches found', () => {
    beforeEach(() => {
      createComponent('_branch_1_', { branch: '_branch_1_' });
    });

    it('renders only the branch searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('_branch_1_');
    });

    it('should not display empty results message', () => {
      expect(findNoResults().exists()).toBe(false);
    });

    it('should signify this branch is selected', () => {
      expect(wrapper.vm.isSelected('_branch_1_')).toBe(true);
    });

    it('should signify the branch is not selected', () => {
      expect(wrapper.vm.isSelected('_not_selected_branch_')).toBe(false);
    });

    describe('Custom events', () => {
      it('should emit selectBranch if an branch is clicked', () => {
        findDropdownItemByIndex(0).vm.$emit('click');

        expect(wrapper.emitted('selectBranch')).toEqual([['_branch_1_']]);
        expect(wrapper.vm.searchTerm).toBe('_branch_1_');
      });
    });
  });

  describe('Case insensitive for search term', () => {
    beforeEach(() => {
      createComponent('_BrAnCh_1_');
    });

    it('renders only the branch searched for', () => {
      expect(findAllDropdownItems()).toHaveLength(1);
      expect(findDropdownItemByIndex(0).text()).toBe('_branch_1_');
    });
  });
});
