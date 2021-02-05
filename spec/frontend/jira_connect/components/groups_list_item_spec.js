import { mount, shallowMount } from '@vue/test-utils';
import { GlAvatar, GlButton } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import GroupsListItem from '~/jira_connect/components/groups_list_item.vue';
import * as JiraConnectApi from '~/jira_connect/api';
import { mockGroup1 } from '../mock_data';

describe('GroupsListItem', () => {
  let wrapper;
  const mockSubscriptionPath = 'subscriptionPath';

  const reloadSpy = jest.fn();

  global.AP = {
    navigator: {
      reload: reloadSpy,
    },
  };

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = extendedWrapper(
      mountFn(GroupsListItem, {
        propsData: {
          group: mockGroup1,
        },
        provide: {
          subscriptionsPath: mockSubscriptionPath,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlAvatar = () => wrapper.find(GlAvatar);
  const findGroupName = () => wrapper.findByTestId('group-list-item-name');
  const findGroupDescription = () => wrapper.findByTestId('group-list-item-description');
  const findLinkButton = () => wrapper.find(GlButton);
  const clickLinkButton = () => findLinkButton().trigger('click');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders group avatar', () => {
      expect(findGlAvatar().exists()).toBe(true);
      expect(findGlAvatar().props('src')).toBe(mockGroup1.avatar_url);
    });

    it('renders group name', () => {
      expect(findGroupName().text()).toBe(mockGroup1.full_name);
    });

    it('renders group description', () => {
      expect(findGroupDescription().text()).toBe(mockGroup1.description);
    });

    it('renders Link button', () => {
      expect(findLinkButton().exists()).toBe(true);
      expect(findLinkButton().text()).toBe('Link');
    });
  });

  describe('on Link button click', () => {
    let addSubscriptionSpy;

    beforeEach(() => {
      createComponent({ mountFn: mount });

      addSubscriptionSpy = jest.spyOn(JiraConnectApi, 'addSubscription').mockResolvedValue();
    });

    it('sets button to loading and sends request', async () => {
      expect(findLinkButton().props('loading')).toBe(false);

      clickLinkButton();

      await wrapper.vm.$nextTick();

      expect(findLinkButton().props('loading')).toBe(true);

      expect(addSubscriptionSpy).toHaveBeenCalledWith(mockSubscriptionPath, mockGroup1.full_path);
    });

    describe('when request is successful', () => {
      it('reloads the page', async () => {
        clickLinkButton();

        await waitForPromises();

        expect(reloadSpy).toHaveBeenCalled();
      });
    });

    describe('when request has errors', () => {
      const mockErrorMessage = 'error message';
      const mockError = { response: { data: { error: mockErrorMessage } } };

      beforeEach(() => {
        addSubscriptionSpy = jest
          .spyOn(JiraConnectApi, 'addSubscription')
          .mockRejectedValue(mockError);
      });

      it('emits `error` event', async () => {
        clickLinkButton();

        await waitForPromises();

        expect(reloadSpy).not.toHaveBeenCalled();
        expect(wrapper.emitted('error')[0][0]).toBe(mockErrorMessage);
      });
    });
  });
});
