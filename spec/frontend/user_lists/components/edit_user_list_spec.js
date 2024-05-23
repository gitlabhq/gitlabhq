import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import EditUserList from '~/user_lists/components/edit_user_list.vue';
import UserListForm from '~/user_lists/components/user_list_form.vue';
import createStore from '~/user_lists/store/edit';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

Vue.use(Vuex);

describe('user_lists/components/edit_user_list', () => {
  let wrapper;

  const setInputValue = (value) => wrapper.find('[data-testid="user-list-name"]').setValue(value);

  const click = (button) => wrapper.find(`[data-testid="${button}"]`).trigger('click');
  const clickSave = () => click('save-user-list');

  const destroy = () => wrapper?.destroy();

  const factory = () => {
    destroy();

    wrapper = mount(EditUserList, {
      store: createStore({ projectId: '1', userListIid: '2' }),
      provide: {
        userListsDocsPath: '/docs/user_lists',
      },
    });
  };

  afterEach(() => {
    destroy();
  });

  describe('loading', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserList.mockReturnValue(new Promise(() => {}));
      factory();
    });

    it('should show a loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('loading error', () => {
    const message = 'error creating list';
    let alert;

    beforeEach(async () => {
      Api.fetchFeatureFlagUserList.mockRejectedValue({ message });
      factory();
      await waitForPromises();

      alert = wrapper.findComponent(GlAlert);
    });

    it('should show a flash with the error respopnse', () => {
      expect(alert.text()).toContain(message);
    });

    it('should not be dismissible', () => {
      expect(alert.props('dismissible')).toBe(false);
    });

    it('should not show a user list form', () => {
      expect(wrapper.findComponent(UserListForm).exists()).toBe(false);
    });
  });

  describe('update', () => {
    beforeEach(async () => {
      Api.fetchFeatureFlagUserList.mockResolvedValue({ data: userList });
      factory();

      await nextTick();
    });

    it('should link to the documentation', () => {
      const link = wrapper.find('[data-testid="user-list-docs-link"]');
      expect(link.attributes('href')).toBe('/docs/user_lists');
    });

    it('should link the cancel button to the user list details path', () => {
      const link = wrapper.find('[data-testid="user-list-cancel"]');
      expect(link.attributes('href')).toBe(userList.path);
    });

    it('should show the user list name in the title', () => {
      expect(wrapper.find('[data-testid="user-list-title"]').text()).toBe(`Edit ${userList.name}`);
    });

    describe('success', () => {
      beforeEach(async () => {
        Api.updateFeatureFlagUserList.mockResolvedValue({ data: userList });
        setInputValue('test');
        clickSave();
        await nextTick();
      });

      it('should create a user list with the entered name', () => {
        expect(Api.updateFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: 'test',
          iid: userList.iid,
        });
      });

      it('should redirect to the feature flag details page', () => {
        expect(visitUrl).toHaveBeenCalledWith(userList.path);
      });
    });

    describe('error', () => {
      let alert;
      let message;

      beforeEach(async () => {
        message = 'error creating list';
        Api.updateFeatureFlagUserList.mockRejectedValue({ message });
        setInputValue('test');
        clickSave();
        await waitForPromises();

        alert = wrapper.findComponent(GlAlert);
      });

      it('should show a flash with the error respopnse', () => {
        expect(alert.text()).toContain(message);
      });

      it('should dismiss the error if dismiss is clicked', async () => {
        alert.find('button').trigger('click');

        await nextTick();

        expect(alert.exists()).toBe(false);
      });
    });
  });
});
