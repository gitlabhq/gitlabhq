import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue, { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';

import * as JiraConnectApi from '~/jira_connect/subscriptions/api';
import GroupItemName from '~/jira_connect/subscriptions/components/group_item_name.vue';

import SubscriptionsList from '~/jira_connect/subscriptions/components/subscriptions_list.vue';
import { useJiraConnectSubscriptions } from '~/jira_connect/subscriptions/store';
import { reloadPage } from '~/jira_connect/subscriptions/utils';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockSubscription } from '../mock_data';

jest.mock('~/jira_connect/subscriptions/utils');

Vue.use(PiniaVuePlugin);

describe('SubscriptionsList', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    const pinia = createTestingPinia({ stubActions: false });
    store = useJiraConnectSubscriptions();
    store.$patch({ subscriptions: [mockSubscription] });

    wrapper = mount(SubscriptionsList, {
      pinia,
    });
  };

  const findUnlinkButton = () => wrapper.findComponent(GlButton);
  const clickUnlinkButton = () => findUnlinkButton().trigger('click');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "name" cell correctly', () => {
      const groupItemNames = wrapper.findAllComponents(GroupItemName);
      expect(groupItemNames.wrappers).toHaveLength(1);

      const item = groupItemNames.at(0);
      expect(item.props('group')).toBe(mockSubscription.group);
    });

    it('renders "created at" cell correctly', () => {
      const timeAgoTooltips = wrapper.findAllComponents(TimeagoTooltip);
      expect(timeAgoTooltips.wrappers).toHaveLength(1);

      const item = timeAgoTooltips.at(0);
      expect(item.props('time')).toBe(mockSubscription.created_at);
    });
  });

  describe('on "Unlink" button click', () => {
    let removeSubscriptionSpy;

    beforeEach(() => {
      createComponent();
      removeSubscriptionSpy = jest.spyOn(JiraConnectApi, 'removeSubscription').mockResolvedValue();
    });

    it('sets button to loading and sends request', async () => {
      expect(findUnlinkButton().props('loading')).toBe(false);

      clickUnlinkButton();

      await nextTick();

      expect(findUnlinkButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(removeSubscriptionSpy).toHaveBeenCalledWith(mockSubscription.unlink_path);
    });

    describe('when request is successful', () => {
      it('reloads the page', async () => {
        clickUnlinkButton();

        await waitForPromises();

        expect(reloadPage).toHaveBeenCalled();
      });
    });

    describe('when request has errors', () => {
      const mockErrorMessage = 'error message';
      const mockError = { response: { data: { error: mockErrorMessage } } };

      beforeEach(() => {
        jest.spyOn(JiraConnectApi, 'removeSubscription').mockRejectedValue(mockError);
      });

      it('sets alert', async () => {
        const setAlertSpy = jest.spyOn(store, 'setAlert');
        clickUnlinkButton();

        await waitForPromises();

        expect(reloadPage).not.toHaveBeenCalled();
        expect(setAlertSpy).toHaveBeenCalledWith({
          message: mockErrorMessage,
          variant: 'danger',
        });
      });
    });
  });
});
