import { GlButton, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import namespaceWorkItemTypesQueryResponse from 'test_fixtures/graphql/work_items/namespace_work_item_types.query.graphql.json';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { isLoggedIn } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import WorkItemNotificationsWidget from '~/work_items/components/work_item_notifications_widget.vue';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';

import { updateWorkItemNotificationsMutationResponse } from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/vue_shared/plugins/global_toast');

describe('WorkItemActions component', () => {
  Vue.use(VueApollo);

  let wrapper;
  const mockWorkItemReference = 'gitlab-org/gitlab-test#1';

  const findNotificationsButton = () => wrapper.findComponent(GlButton);

  const $toast = {
    show: jest.fn(),
    hide: jest.fn(),
  };

  const typesQuerySuccessHandler = jest.fn().mockResolvedValue(namespaceWorkItemTypesQueryResponse);
  const toggleNotificationsOffHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemNotificationsMutationResponse(false));
  const toggleNotificationsOnHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemNotificationsMutationResponse(true));
  const toggleNotificationsFailureHandler = jest
    .fn()
    .mockRejectedValue(new Error('Failed to subscribe'));

  const createComponent = ({
    canUpdate = true,
    subscribedToNotifications = false,
    notificationsMutationHandler,
    workItemType = 'Task',
    workItemReference = mockWorkItemReference,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemNotificationsWidget, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: createMockApollo([
        [namespaceWorkItemTypesQuery, typesQuerySuccessHandler],
        [updateWorkItemNotificationsMutation, notificationsMutationHandler],
      ]),
      propsData: {
        fullPath: 'gitlab-org/gitlab-test',
        workItemId: 'gid://gitlab/WorkItem/1',
        canUpdate,
        subscribedToNotifications,
        workItemType,
        workItemReference,
      },
      mocks: {
        $toast,
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  it('renders button', () => {
    createComponent();

    expect(findNotificationsButton().exists()).toBe(true);
  });

  describe('notifications action', () => {
    beforeEach(() => {
      createComponent();
      isLoggedIn.mockReturnValue(true);
    });

    it.each`
      scenario                   | subscribedToNotifications | notificationsMutationHandler     | subscribed | toastMessage
      ${'notifications are off'} | ${false}                  | ${toggleNotificationsOnHandler}  | ${true}    | ${'Notifications turned on.'}
      ${'notifications are on'}  | ${true}                   | ${toggleNotificationsOffHandler} | ${false}   | ${'Notifications turned off.'}
    `(
      'calls mutation and displays toast when notification button is clicked while $scenario',
      async ({
        subscribedToNotifications,
        notificationsMutationHandler,
        subscribed,
        toastMessage,
      }) => {
        createComponent({
          notificationsMutationHandler,
          subscribedToNotifications,
        });

        findNotificationsButton().vm.$emit('click');
        await waitForPromises();

        expect(notificationsMutationHandler).toHaveBeenCalledWith({
          input: {
            id: 'gid://gitlab/WorkItem/1',
            subscribed,
          },
        });
        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    it.each`
      scenario                   | subscribedToNotifications | icon
      ${'notifications are off'} | ${false}                  | ${'notifications-off'}
      ${'notifications are on'}  | ${true}                   | ${'notifications'}
    `('uses the correct icon when $scenario', ({ subscribedToNotifications, icon }) => {
      createComponent({ subscribedToNotifications });
      expect(findNotificationsButton().findComponent(GlIcon).props('name')).toBe(icon);
    });

    it('emits error when the update notification mutation fails', async () => {
      createComponent({
        notificationsMutationHandler: toggleNotificationsFailureHandler,
      });

      findNotificationsButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Failed to subscribe']]);
    });
  });
});
