import { GlAlert, GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { uniq } from 'lodash';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Api from '~/api';
import UserList from '~/user_lists/components/user_list.vue';
import createStore from '~/user_lists/store/show';
import { parseUserIds, stringifyUserIds } from '~/user_lists/store/utils';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');

Vue.use(Vuex);

describe('User List', () => {
  let wrapper;

  const click = (testId) => wrapper.find(`[data-testid="${testId}"]`).trigger('click');

  const findUserIds = () => wrapper.findAll('[data-testid="user-id"]');

  const destroy = () => wrapper?.destroy();

  const factory = () => {
    destroy();

    wrapper = mount(UserList, {
      store: createStore({ projectId: '1', userListIid: '2' }),
      propsData: {
        emptyStatePath: '/empty_state.svg',
      },
    });
  };

  describe('loading', () => {
    let resolveFn;

    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockReturnValue(
        new Promise((resolve) => {
          resolveFn = resolve;
        }),
      );
      factory();
    });

    afterEach(() => {
      resolveFn();
    });

    it('shows a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('success', () => {
    let userIds;

    beforeEach(async () => {
      userIds = parseUserIds(userList.user_xids);
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: userList });
      factory();

      await nextTick();
    });

    it('requests the user list on mount', () => {
      expect(Api.fetchFeatureFlagUserList).toHaveBeenCalledWith('1', '2');
    });

    it('shows the list name', () => {
      expect(wrapper.find('h3').text()).toBe(userList.name);
    });

    it('shows an add users button', () => {
      expect(wrapper.find('[data-testid="add-users"]').text()).toBe('Add Users');
    });

    it('shows an edit list button', () => {
      expect(wrapper.find('[data-testid="edit-user-list"]').text()).toBe('Edit');
    });

    it('shows a row for every id', () => {
      expect(wrapper.findAll('[data-testid="user-id-row"]')).toHaveLength(userIds.length);
    });

    it('shows one id on each row', () => {
      findUserIds().wrappers.forEach((w, i) => expect(w.text()).toBe(userIds[i]));
    });

    it('shows a delete button for every row', () => {
      expect(wrapper.findAll('[data-testid="delete-user-id"]')).toHaveLength(userIds.length);
    });

    describe('adding users', () => {
      const newIds = ['user3', 'user4', 'user5', 'test', 'example', 'foo'];
      let receivedUserIds;
      let parsedReceivedUserIds;

      beforeEach(async () => {
        Api.updateFeatureFlagUserList.mockResolvedValue(userList);
        click('add-users');
        await nextTick();
        wrapper.find('#add-user-ids').setValue(`${stringifyUserIds(newIds)},`);
        click('confirm-add-user-ids');
        await nextTick();
        [[, { user_xids: receivedUserIds }]] = Api.updateFeatureFlagUserList.mock.calls;
        parsedReceivedUserIds = parseUserIds(receivedUserIds);
      });

      it('should add user IDs to the user list', () => {
        newIds.forEach((id) => expect(receivedUserIds).toContain(id));
      });

      it('should not remove existing user ids', () => {
        userIds.forEach((id) => expect(receivedUserIds).toContain(id));
      });

      it('should not submit empty IDs', () => {
        parsedReceivedUserIds.forEach((id) => expect(id).not.toBe(''));
      });

      it('should not create duplicate entries', () => {
        expect(uniq(parsedReceivedUserIds)).toEqual(parsedReceivedUserIds);
      });

      it('should display the new IDs', () => {
        const userIdWrappers = findUserIds();
        newIds.forEach((id) => {
          const userIdWrapper = userIdWrappers.wrappers.find((w) => w.text() === id);
          expect(userIdWrapper.exists()).toBe(true);
        });
      });
    });

    describe('deleting users', () => {
      let receivedUserIds;

      beforeEach(async () => {
        Api.updateFeatureFlagUserList.mockResolvedValue(userList);
        click('delete-user-id');
        await nextTick();
        [[, { user_xids: receivedUserIds }]] = Api.updateFeatureFlagUserList.mock.calls;
      });

      it('should remove the ID clicked', () => {
        expect(receivedUserIds).not.toContain(userIds[0]);
      });

      it('should not display the deleted user', () => {
        const userIdWrappers = findUserIds();
        const userIdWrapper = userIdWrappers.wrappers.find((w) => w.text() === userIds[0]);
        expect(userIdWrapper).toBeUndefined();
      });
    });
  });

  describe('error', () => {
    const findAlert = () => wrapper.findComponent(GlAlert);

    beforeEach(async () => {
      Api.fetchFeatureFlagUserList.mockRejectedValue();
      factory();

      await nextTick();
    });

    it('displays the alert message', () => {
      const alert = findAlert();
      expect(alert.text()).toBe('Unable to load user list. Reload the page and try again.');
    });

    it('can dismiss the alert', async () => {
      const alert = findAlert();
      alert.find('button').trigger('click');

      await nextTick();

      expect(alert.exists()).toBe(false);
    });
  });

  describe('empty list', () => {
    beforeEach(async () => {
      Api.fetchFeatureFlagUserList.mockResolvedValueOnce({ data: { ...userList, user_xids: '' } });
      factory();

      await nextTick();
    });

    it('displays an empty state', () => {
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });
  });
});
