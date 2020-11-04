import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import Api from '~/api';
import createStore from '~/feature_flags/store/new';
import GitlabUserList from '~/feature_flags/components/strategies/gitlab_user_list.vue';
import { userListStrategy, userList } from '../../mock_data';

jest.mock('~/api');

const DEFAULT_PROPS = {
  strategy: userListStrategy,
};

const localVue = createLocalVue();
localVue.use(Vuex);

describe('~/feature_flags/components/strategies/gitlab_user_list.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    mount(GitlabUserList, {
      localVue,
      store: createStore({ projectId: '1' }),
      propsData: { ...DEFAULT_PROPS, ...props },
    });

  const findDropdown = () => wrapper.find(GlDropdown);

  describe('with user lists', () => {
    const findDropdownItem = () => wrapper.find(GlDropdownItem);

    beforeEach(() => {
      Api.searchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
      wrapper = factory();
    });

    it('should show the input for userListId with the correct value', () => {
      const dropdownWrapper = findDropdown();
      expect(dropdownWrapper.exists()).toBe(true);
      expect(dropdownWrapper.props('text')).toBe(userList.name);
    });

    it('should show a check for the selected list', () => {
      const itemWrapper = findDropdownItem();
      expect(itemWrapper.props('isChecked')).toBe(true);
    });

    it('should display the name of the list in the drop;down', () => {
      const itemWrapper = findDropdownItem();
      expect(itemWrapper.text()).toBe(userList.name);
    });

    it('should emit a change event when altering the userListId', () => {
      const inputWrapper = findDropdownItem();
      inputWrapper.vm.$emit('click');
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            userList,
          },
        ],
      ]);
    });

    it('should search when the filter changes', async () => {
      let r;
      Api.searchFeatureFlagUserLists.mockReturnValue(
        new Promise(resolve => {
          r = resolve;
        }),
      );
      const searchWrapper = wrapper.find(GlSearchBoxByType);
      searchWrapper.vm.$emit('input', 'new');
      await wrapper.vm.$nextTick();
      const loadingIcon = wrapper.find(GlLoadingIcon);

      expect(loadingIcon.exists()).toBe(true);
      expect(Api.searchFeatureFlagUserLists).toHaveBeenCalledWith('1', 'new');

      r({ data: [userList] });

      await wrapper.vm.$nextTick();

      expect(loadingIcon.exists()).toBe(false);
    });
  });

  describe('without user lists', () => {
    beforeEach(() => {
      Api.searchFeatureFlagUserLists.mockResolvedValue({ data: [] });
      wrapper = factory({ strategy: { ...userListStrategy, userList: null } });
    });

    it('should display a message that there are no user lists', () => {
      expect(wrapper.text()).toContain('There are no configured user lists');
    });

    it('should dispaly a message that no list has been selected', () => {
      expect(findDropdown().text()).toContain('No user list selected');
    });
  });
});
