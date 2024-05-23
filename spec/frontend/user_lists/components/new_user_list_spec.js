import { GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import NewUserList from '~/user_lists/components/new_user_list.vue';
import createStore from '~/user_lists/store/new';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

Vue.use(Vuex);

describe('user_lists/components/new_user_list', () => {
  let wrapper;

  const setInputValue = (value) => wrapper.find('[data-testid="user-list-name"]').setValue(value);

  const click = (button) => wrapper.find(`[data-testid="${button}"]`).trigger('click');

  beforeEach(() => {
    wrapper = mount(NewUserList, {
      store: createStore({ projectId: '1' }),
      provide: {
        featureFlagsPath: '/feature_flags',
        userListsDocsPath: '/docs/user_lists',
      },
    });
  });

  it('should link to the documentation', () => {
    const link = wrapper.find('[data-testid="user-list-docs-link"]');
    expect(link.attributes('href')).toBe('/docs/user_lists');
  });

  it('should link the cancel buton back to feature flags', () => {
    const cancel = wrapper.find('[data-testid="user-list-cancel"');
    expect(cancel.attributes('href')).toBe('/feature_flags');
  });

  describe('create', () => {
    describe('success', () => {
      beforeEach(async () => {
        Api.createFeatureFlagUserList.mockResolvedValue({ data: userList });
        setInputValue('test');
        click('save-user-list');
        await nextTick();
      });

      it('should create a user list with the entered name', () => {
        expect(Api.createFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: 'test',
          user_xids: '',
        });
      });

      it('should redirect to the feature flag details page', () => {
        expect(visitUrl).toHaveBeenCalledWith(userList.path);
      });
    });

    describe('error', () => {
      let alert;

      beforeEach(async () => {
        Api.createFeatureFlagUserList.mockRejectedValue({ message: 'error creating list' });
        setInputValue('test');
        click('save-user-list');

        await waitForPromises();

        alert = wrapper.findComponent(GlAlert);
      });

      it('should show a flash with the error respopnse', () => {
        expect(alert.text()).toContain('error creating list');
      });

      it('should dismiss the error when the dismiss button is clicked', async () => {
        alert.find('button').trigger('click');

        await nextTick();

        expect(alert.exists()).toBe(false);
      });
    });
  });
});
