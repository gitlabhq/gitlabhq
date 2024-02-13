import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarSubscriptionWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import issueSubscribedQuery from '~/sidebar/queries/issue_subscribed.query.graphql';
import updateMergeRequestSubscriptionMutation from '~/sidebar/queries/update_merge_request_subscription.mutation.graphql';
import toast from '~/vue_shared/plugins/global_toast';
import {
  issueSubscriptionsResponse,
  mergeRequestSubscriptionMutationResponse,
} from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');

Vue.use(VueApollo);

describe('Sidebar Subscriptions Widget', () => {
  let wrapper;
  let fakeApollo;
  let subscriptionMutationHandler;

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findDropdownToggleItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  const createComponent = ({
    subscriptionsQueryHandler = jest.fn().mockResolvedValue(issueSubscriptionsResponse()),
    issuableType = 'issue',
  } = {}) => {
    subscriptionMutationHandler = jest
      .fn()
      .mockResolvedValue(mergeRequestSubscriptionMutationResponse);
    fakeApollo = createMockApollo([
      [issueSubscribedQuery, subscriptionsQueryHandler],
      [updateMergeRequestSubscriptionMutation, subscriptionMutationHandler],
    ]);

    wrapper = shallowMount(SidebarSubscriptionWidget, {
      apolloProvider: fakeApollo,
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'group/project',
        iid: '1',
        issuableType,
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('when user is not subscribed to the issue', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });
    it('toggle is unchecked', () => {
      expect(findToggle().props('value')).toBe(false);
    });

    it('emits `subscribedUpdated` event with a `false` payload', () => {
      expect(wrapper.emitted('subscribedUpdated')).toEqual([[false]]);
    });
  });

  describe('when user is subscribed to the issue', () => {
    beforeEach(() => {
      createComponent({
        subscriptionsQueryHandler: jest.fn().mockResolvedValue(issueSubscriptionsResponse(true)),
      });
      return waitForPromises();
    });

    it('toggle is checked', () => {
      expect(findToggle().props('value')).toBe(true);
    });

    it('emits `subscribedUpdated` event with a `true` payload', () => {
      expect(wrapper.emitted('subscribedUpdated')).toEqual([[true]]);
    });
  });

  it('displays an alert message when query is rejected', async () => {
    createComponent({
      subscriptionsQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  describe('merge request', () => {
    it('displays toast when mutation is successful', async () => {
      createComponent({
        issuableType: 'merge_request',
        subscriptionsQueryHandler: jest.fn().mockResolvedValue(issueSubscriptionsResponse(true)),
      });
      await waitForPromises();

      await findDropdownToggleItem().vm.$emit('action');

      await waitForPromises();

      expect(toast).toHaveBeenCalledWith('Notifications turned on.');
    });
  });
});
