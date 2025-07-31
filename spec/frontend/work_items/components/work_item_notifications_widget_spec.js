import { GlButton, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { isLoggedIn } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import WorkItemNotificationsWidget from '~/work_items/components/work_item_notifications_widget.vue';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import getWorkItemNotificationsByIdQuery from '~/work_items/graphql/get_work_item_notifications_by_id.query.graphql';
import {
  namespaceWorkItemTypesQueryResponse,
  workItemNotificationsResponse,
  updateWorkItemNotificationsMutationResponse,
} from '../mock_data';

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
  const notificationOffQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemNotificationsResponse(false));
  const notificationOnQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemNotificationsResponse(true));
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
    notificationsMutationHandler,
    workItemType = 'Task',
    workItemReference = mockWorkItemReference,
    notificationsQueryHandler = notificationOnQueryHandler,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemNotificationsWidget, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: createMockApollo([
        [namespaceWorkItemTypesQuery, typesQuerySuccessHandler],
        [getWorkItemNotificationsByIdQuery, notificationsQueryHandler],
        [updateWorkItemNotificationsMutation, notificationsMutationHandler],
      ]),
      propsData: {
        fullPath: 'gitlab-org/gitlab-test',
        workItemId: 'gid://gitlab/WorkItem/1',
        canUpdate,
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

  it('does not render button if user is not logged in', () => {
    isLoggedIn.mockReturnValue(false);
    createComponent();

    expect(findNotificationsButton().exists()).toBe(false);
  });

  describe('notifications action', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      scenario        | notificationsQueryHandler      | notificationsMutationHandler     | subscribed | toastMessage
      ${'turned off'} | ${notificationOnQueryHandler}  | ${toggleNotificationsOffHandler} | ${false}   | ${'Notifications turned off.'}
      ${'turned on'}  | ${notificationOffQueryHandler} | ${toggleNotificationsOnHandler}  | ${true}    | ${'Notifications turned on.'}
    `(
      'calls mutation and displays toast when notification toggle is $scenario',
      async ({
        notificationsMutationHandler,
        subscribed,
        toastMessage,
        notificationsQueryHandler,
      }) => {
        createComponent({
          notificationsMutationHandler,
          notificationsQueryHandler,
        });
        await waitForPromises();

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
      scenario                   | icon                   | notificationsQueryHandler
      ${'notifications are off'} | ${'notifications-off'} | ${notificationOffQueryHandler}
      ${'notifications are on'}  | ${'notifications'}     | ${notificationOnQueryHandler}
    `('uses the correct icon when $scenario', async ({ notificationsQueryHandler, icon }) => {
      createComponent({ notificationsQueryHandler });
      await waitForPromises();

      expect(findNotificationsButton().findComponent(GlIcon).props('name')).toBe(icon);
    });

    it.each`
      scenario                   | dataSubscribed | notificationsQueryHandler
      ${'notifications are off'} | ${'false'}     | ${notificationOffQueryHandler}
      ${'notifications are on'}  | ${'true'}      | ${notificationOnQueryHandler}
    `(
      'has the correct data-subscribed attribute when $scenario',
      async ({ notificationsQueryHandler, dataSubscribed }) => {
        createComponent({ notificationsQueryHandler });
        await waitForPromises();

        expect(findNotificationsButton().attributes('data-subscribed')).toBe(dataSubscribed);
      },
    );

    it('emits error when the update notification mutation fails', async () => {
      createComponent({
        notificationsMutationHandler: toggleNotificationsFailureHandler,
      });
      await waitForPromises();

      findNotificationsButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([['Failed to subscribe']]);
    });
  });
});
