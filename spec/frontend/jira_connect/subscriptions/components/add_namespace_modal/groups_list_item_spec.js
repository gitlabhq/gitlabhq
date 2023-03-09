import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';

import * as JiraConnectApi from '~/jira_connect/subscriptions/api';
import GroupItemName from '~/jira_connect/subscriptions/components/group_item_name.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list_item.vue';
import { persistAlert, reloadPage } from '~/jira_connect/subscriptions/utils';
import {
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
  I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
  INTEGRATIONS_DOC_LINK,
} from '~/jira_connect/subscriptions/constants';
import createStore from '~/jira_connect/subscriptions/store';
import { mockGroup1 } from '../../mock_data';

jest.mock('~/jira_connect/subscriptions/utils');

describe('GroupsListItem', () => {
  let wrapper;
  let store;

  const mockAddSubscriptionsPath = '/addSubscriptionsPath';

  const createComponent = ({ mountFn = shallowMount, provide } = {}) => {
    store = createStore();

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = mountFn(GroupsListItem, {
      store,
      propsData: {
        group: mockGroup1,
      },
      provide: {
        addSubscriptionsPath: mockAddSubscriptionsPath,
        ...provide,
      },
    });
  };

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
    describe('when jiraConnectOauth feature flag is disabled', () => {
      let addSubscriptionSpy;

      beforeEach(() => {
        createComponent({ mountFn: mount });

        addSubscriptionSpy = jest.spyOn(JiraConnectApi, 'addSubscription').mockResolvedValue();
      });

      it('sets button to loading and sends request', async () => {
        expect(findLinkButton().props('loading')).toBe(false);

        clickLinkButton();
        await nextTick();

        expect(findLinkButton().props('loading')).toBe(true);
        await waitForPromises();

        expect(addSubscriptionSpy).toHaveBeenCalledWith(
          mockAddSubscriptionsPath,
          mockGroup1.full_path,
        );
        expect(persistAlert).toHaveBeenCalledWith({
          linkUrl: INTEGRATIONS_DOC_LINK,
          message: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_MESSAGE,
          title: I18N_ADD_SUBSCRIPTION_SUCCESS_ALERT_TITLE,
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

    describe('when jiraConnectOauth feature flag is enabled', () => {
      const mockSubscriptionsPath = '/subscriptions';

      beforeEach(() => {
        createComponent({
          mountFn: mount,
          provide: {
            subscriptionsPath: mockSubscriptionsPath,
            glFeatures: { jiraConnectOauth: true },
          },
        });
      });

      it('dispatches `addSubscription` action', async () => {
        clickLinkButton();
        await nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('addSubscription', {
          namespacePath: mockGroup1.full_path,
          subscriptionsPath: mockSubscriptionsPath,
        });
      });
    });
  });
});
