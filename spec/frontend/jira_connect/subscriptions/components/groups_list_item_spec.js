import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';

import * as JiraConnectApi from '~/jira_connect/subscriptions/api';
import GroupItemName from '~/jira_connect/subscriptions/components/group_item_name.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/groups_list_item.vue';
import { persistAlert, reloadPage } from '~/jira_connect/subscriptions/utils';
import { mockGroup1 } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils');

describe('GroupsListItem', () => {
  let wrapper;
  const mockSubscriptionPath = 'subscriptionPath';

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(GroupsListItem, {
      propsData: {
        group: mockGroup1,
      },
      provide: {
        subscriptionsPath: mockSubscriptionPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGroupItemName = () => wrapper.findComponent(GroupItemName);
  const findLinkButton = () => wrapper.findComponent(GlButton);
  const clickLinkButton = () => findLinkButton().trigger('click');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GroupItemName', () => {
      expect(findGroupItemName().exists()).toBe(true);
      expect(findGroupItemName().props('group')).toBe(mockGroup1);
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

      await waitForPromises();

      expect(addSubscriptionSpy).toHaveBeenCalledWith(mockSubscriptionPath, mockGroup1.full_path);
      expect(persistAlert).toHaveBeenCalledWith({
        linkUrl: '/help/integration/jira_development_panel.html#usage',
        message:
          'You should now see GitLab.com activity inside your Jira Cloud issues. %{linkStart}Learn more%{linkEnd}',
        title: 'Namespace successfully linked',
        variant: 'success',
      });
    });

    describe('when request is successful', () => {
      it('reloads the page', async () => {
        clickLinkButton();

        await waitForPromises();

        expect(reloadPage).toHaveBeenCalled();
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

        expect(reloadPage).not.toHaveBeenCalled();
        expect(wrapper.emitted('error')[0][0]).toBe(mockErrorMessage);
      });
    });
  });
});
