import { GlIcon, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import SidebarSubscriptionWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import issueSubscribedQuery from '~/sidebar/queries/issue_subscribed.query.graphql';
import { issueSubscriptionsResponse } from '../../mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Sidebar Subscriptions Widget', () => {
  let wrapper;
  let fakeApollo;

  const findEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = ({
    subscriptionsQueryHandler = jest.fn().mockResolvedValue(issueSubscriptionsResponse()),
  } = {}) => {
    fakeApollo = createMockApollo([[issueSubscribedQuery, subscriptionsQueryHandler]]);

    wrapper = shallowMount(SidebarSubscriptionWidget, {
      apolloProvider: fakeApollo,
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'group/project',
        iid: '1',
        issuableType: 'issue',
      },
      stubs: {
        SidebarEditableItem,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  it('passes a `loading` prop as true to editable item when query is loading', () => {
    createComponent();

    expect(findEditableItem().props('loading')).toBe(true);
  });

  describe('when user is not subscribed to the issue', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
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

    it('passes a `loading` prop as false to editable item', () => {
      expect(findEditableItem().props('loading')).toBe(false);
    });

    it('toggle is checked', () => {
      expect(findToggle().props('value')).toBe(true);
    });

    it('emits `subscribedUpdated` event with a `true` payload', () => {
      expect(wrapper.emitted('subscribedUpdated')).toEqual([[true]]);
    });
  });

  describe('when emails are disabled', () => {
    it('toggle is disabled and off when user is subscribed', async () => {
      createComponent({
        subscriptionsQueryHandler: jest
          .fn()
          .mockResolvedValue(issueSubscriptionsResponse(true, true)),
      });
      await waitForPromises();

      expect(findIcon().props('name')).toBe('notifications-off');
      expect(findToggle().props('disabled')).toBe(true);
    });

    it('toggle is disabled and off when user is not subscribed', async () => {
      createComponent({
        subscriptionsQueryHandler: jest
          .fn()
          .mockResolvedValue(issueSubscriptionsResponse(false, true)),
      });
      await waitForPromises();

      expect(findIcon().props('name')).toBe('notifications-off');
      expect(findToggle().props('disabled')).toBe(true);
    });
  });

  it('displays a flash message when query is rejected', async () => {
    createComponent({
      subscriptionsQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });
});
