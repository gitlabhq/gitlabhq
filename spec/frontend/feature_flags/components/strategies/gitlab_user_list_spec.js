import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import Api from '~/api';
import GitlabUserList from '~/feature_flags/components/strategies/gitlab_user_list.vue';
import createStore from '~/feature_flags/store/new';
import { userListStrategy, userList } from '../../mock_data';

jest.mock('~/api');

const DEFAULT_PROPS = {
  strategy: userListStrategy,
};

Vue.use(Vuex);

describe('~/feature_flags/components/strategies/gitlab_user_list.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    mount(GitlabUserList, {
      store: createStore({ projectId: '1' }),
      propsData: { ...DEFAULT_PROPS, ...props },
    });

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  describe('with user lists', () => {
    const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);

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
        new Promise((resolve) => {
          r = resolve;
        }),
      );
      const searchWrapper = wrapper.findComponent(GlSearchBoxByType);
      searchWrapper.vm.$emit('input', 'new');
      await nextTick();
      const loadingIcon = wrapper.findComponent(GlLoadingIcon);

      expect(loadingIcon.exists()).toBe(true);
      expect(Api.searchFeatureFlagUserLists).toHaveBeenCalledWith('1', 'new');

      r({ data: [userList] });

      await nextTick();

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
