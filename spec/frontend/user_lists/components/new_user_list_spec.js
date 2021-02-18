import { GlAlert } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { redirectTo } from '~/lib/utils/url_utility';
import NewUserList from '~/user_lists/components/new_user_list.vue';
import createStore from '~/user_lists/store/new';
import { userList } from '../../feature_flags/mock_data';

jest.mock('~/api');
jest.mock('~/lib/utils/url_utility');

const localVue = createLocalVue(Vue);
localVue.use(Vuex);

describe('user_lists/components/new_user_list', () => {
  let wrapper;

  const setInputValue = (value) => wrapper.find('[data-testid="user-list-name"]').setValue(value);

  const click = (button) => wrapper.find(`[data-testid="${button}"]`).trigger('click');

  beforeEach(() => {
    wrapper = mount(NewUserList, {
      localVue,
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
      beforeEach(() => {
        Api.createFeatureFlagUserList.mockResolvedValue({ data: userList });
        setInputValue('test');
        click('save-user-list');
        return wrapper.vm.$nextTick();
      });

      it('should create a user list with the entered name', () => {
        expect(Api.createFeatureFlagUserList).toHaveBeenCalledWith('1', {
          name: 'test',
          user_xids: '',
        });
      });

      it('should redirect to the feature flag details page', () => {
        expect(redirectTo).toHaveBeenCalledWith(userList.path);
      });
    });

    describe('error', () => {
      let alert;

      beforeEach(async () => {
        Api.createFeatureFlagUserList.mockRejectedValue({ message: 'error creating list' });
        setInputValue('test');
        click('save-user-list');

        await waitForPromises();

        alert = wrapper.find(GlAlert);
      });

      it('should show a flash with the error respopnse', () => {
        expect(alert.text()).toContain('error creating list');
      });

      it('should dismiss the error when the dismiss button is clicked', async () => {
        alert.find('button').trigger('click');

        await wrapper.vm.$nextTick();

        expect(alert.exists()).toBe(false);
      });
    });
  });
});
