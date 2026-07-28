import { GlAnimatedNotificationIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { parseBoolean } from '~/lib/utils/common_utils';
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

  const findNotificationIcon = () => wrapper.findComponent(GlAnimatedNotificationIcon);
  const findNotificationIconIsOn = () => {
    const icon = findNotificationIcon();
    return icon.props('isOn') ?? parseBoolean(icon.attributes('is-on'));
  };
  const findSubscribeButton = () => wrapper.findComponentByTestId('subscribe-button');

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

    wrapper = shallowMountExtended(SidebarSubscriptionWidget, {
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
    it('renders the notification icon in the on (unsubscribed) state', () => {
      expect(findSubscribeButton().exists()).toBe(true);
      expect(findNotificationIconIsOn()).toBe(true);
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

    it('renders the notification icon in the off (subscribed) state', () => {
      expect(findSubscribeButton().exists()).toBe(true);
      expect(findNotificationIconIsOn()).toBe(false);
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
    it('renders as icon button', async () => {
      createComponent({ issuableType: 'merge_request' });
      await waitForPromises();

      expect(findSubscribeButton().exists()).toBe(true);
      expect(findNotificationIcon().exists()).toBe(true);
    });

    it('is disabled while loading', () => {
      createComponent({ issuableType: 'merge_request' });

      expect(findSubscribeButton().attributes('disabled')).toBeDefined();
    });

    it('displays toast when mutation is successful', async () => {
      createComponent({ issuableType: 'merge_request' });
      await waitForPromises();

      await findSubscribeButton().vm.$emit('click');

      await waitForPromises();

      expect(toast).toHaveBeenCalledWith('Notifications turned on.');
    });
  });
});
