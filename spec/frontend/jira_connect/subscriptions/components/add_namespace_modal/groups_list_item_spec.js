import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import Vue from 'vue';

import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import GroupItemName from '~/jira_connect/subscriptions/components/group_item_name.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list_item.vue';
import { I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE } from '~/jira_connect/subscriptions/constants';
import { useJiraConnectSubscriptions } from '~/jira_connect/subscriptions/store';
import { mockGroup1 } from '../../mock_data';

Vue.use(PiniaVuePlugin);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('GroupsListItem', () => {
  let wrapper;
  let store;

  const createComponent = ({ mountFn = shallowMount, provide } = {}) => {
    const pinia = createTestingPinia();
    store = useJiraConnectSubscriptions();

    wrapper = mountFn(GroupsListItem, {
      pinia,
      propsData: {
        group: mockGroup1,
      },
      provide: {
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
    const mockSubscriptionsPath = '/subscriptions';

    beforeEach(() => {
      createComponent({
        mountFn: mount,
        provide: {
          subscriptionsPath: mockSubscriptionsPath,
        },
      });
    });

    it('calls `addSubscription` action', () => {
      clickLinkButton();

      expect(store.addSubscription).toHaveBeenCalledTimes(1);
      expect(store.addSubscription).toHaveBeenCalledWith({
        namespacePath: mockGroup1.full_path,
        subscriptionsPath: mockSubscriptionsPath,
      });
    });

    describe('when `addSubscription` rejects', () => {
      it.each`
        scenario                                       | error                                                                          | expectedMessage
        ${'extracts `errors` from the response body'}  | ${{ response: { data: { errors: 'Server-side errors detail' } } }}             | ${'Server-side errors detail'}
        ${'extracts `message` from the response body'} | ${{ response: { data: { message: 'Server-side message detail' } } }}           | ${'Server-side message detail'}
        ${'prefers `errors` when both are present'}    | ${{ response: { data: { errors: 'errors wins', message: 'message loses' } } }} | ${'errors wins'}
        ${'falls back to the generic message'}         | ${{ response: { data: {} } }}                                                  | ${I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE}
        ${'falls back when no response is present'}    | ${new Error('network')}                                                        | ${I18N_ADD_SUBSCRIPTIONS_ERROR_MESSAGE}
      `('emits `error` with $scenario', async ({ error, expectedMessage }) => {
        store.addSubscription.mockRejectedValue(error);

        await clickLinkButton();
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[expectedMessage]]);
      });

      it('reports the error to Sentry', async () => {
        const error = new Error('network');
        store.addSubscription.mockRejectedValue(error);

        await clickLinkButton();
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });
  });
});
