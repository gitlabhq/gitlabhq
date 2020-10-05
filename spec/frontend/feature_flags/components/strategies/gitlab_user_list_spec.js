import { mount } from '@vue/test-utils';
import { GlFormSelect } from '@gitlab/ui';
import GitlabUserList from '~/feature_flags/components/strategies/gitlab_user_list.vue';
import { userListStrategy, userList } from '../../mock_data';

const DEFAULT_PROPS = {
  strategy: userListStrategy,
  userLists: [userList],
};

describe('~/feature_flags/components/strategies/gitlab_user_list.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    mount(GitlabUserList, { propsData: { ...DEFAULT_PROPS, ...props } });

  describe('with user lists', () => {
    beforeEach(() => {
      wrapper = factory();
    });

    it('should show the input for userListId with the correct value', () => {
      const inputWrapper = wrapper.find(GlFormSelect);
      expect(inputWrapper.exists()).toBe(true);
      expect(inputWrapper.element.value).toBe('2');
    });

    it('should emit a change event when altering the userListId', () => {
      const inputWrapper = wrapper.find(GitlabUserList);
      inputWrapper.vm.$emit('change', {
        userListId: '3',
      });
      expect(wrapper.emitted('change')).toEqual([
        [
          {
            userListId: '3',
          },
        ],
      ]);
    });
  });
  describe('without user lists', () => {
    beforeEach(() => {
      wrapper = factory({ userLists: [] });
    });

    it('should display a message that there are no user lists', () => {
      expect(wrapper.text()).toContain('There are no configured user lists');
    });
  });
});
