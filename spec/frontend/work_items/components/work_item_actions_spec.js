import { GlDropdownDivider, GlModal, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { isLoggedIn } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import {
  TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_ACTION,
  TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
  TEST_ID_DELETE_ACTION,
  TEST_ID_PROMOTE_ACTION,
  TEST_ID_COPY_REFERENCE_ACTION,
  TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
} from '~/work_items/constants';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import {
  convertWorkItemMutationResponse,
  projectWorkItemTypesQueryResponse,
  convertWorkItemMutationErrorResponse,
  workItemByIidResponseFactory,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/vue_shared/plugins/global_toast');

describe('WorkItemActions component', () => {
  Vue.use(VueApollo);

  let wrapper;
  let mockApollo;
  const mockWorkItemReference = 'gitlab-org/gitlab-test#1';
  const mockWorkItemIid = '1';
  const mockFullPath = 'gitlab-org/gitlab-test';
  const mockWorkItemCreateNoteEmail =
    'gitlab-incoming+gitlab-org-gitlab-test-2-ddpzuq0zd2wefzofcpcdr3dg7-issue-1@gmail.com';

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId(TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION);
  const findNotificationsToggleButton = () =>
    wrapper.findByTestId(TEST_ID_NOTIFICATIONS_TOGGLE_ACTION);
  const findDeleteButton = () => wrapper.findByTestId(TEST_ID_DELETE_ACTION);
  const findPromoteButton = () => wrapper.findByTestId(TEST_ID_PROMOTE_ACTION);
  const findCopyReferenceButton = () => wrapper.findByTestId(TEST_ID_COPY_REFERENCE_ACTION);
  const findCopyCreateNoteEmailButton = () =>
    wrapper.findByTestId(TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION);
  const findDropdownItems = () => wrapper.findAll('[data-testid="work-item-actions-dropdown"] > *');
  const findDropdownItemsActual = () =>
    findDropdownItems().wrappers.map((x) => {
      if (x.is(GlDropdownDivider)) {
        return { divider: true };
      }

      return {
        testId: x.attributes('data-testid'),
        text: x.text(),
      };
    });
  const findNotificationsToggle = () => wrapper.findComponent(GlToggle);

  const modalShowSpy = jest.fn();
  const $toast = {
    show: jest.fn(),
    hide: jest.fn(),
  };

  const convertWorkItemMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(convertWorkItemMutationResponse);

  const convertWorkItemMutationErrorHandler = jest
    .fn()
    .mockResolvedValue(convertWorkItemMutationErrorResponse);
  const typesQuerySuccessHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);

  const createComponent = ({
    canUpdate = true,
    canDelete = true,
    isConfidential = false,
    subscribed = false,
    isParentConfidential = false,
    notificationsMock = [updateWorkItemNotificationsMutation, jest.fn()],
    convertWorkItemMutationHandler = convertWorkItemMutationSuccessHandler,
    workItemType = 'Task',
    workItemReference = mockWorkItemReference,
    workItemCreateNoteEmail = mockWorkItemCreateNoteEmail,
    writeQueryCache = false,
  } = {}) => {
    const handlers = [notificationsMock];
    mockApollo = createMockApollo([
      ...handlers,
      [convertWorkItemMutation, convertWorkItemMutationHandler],
      [projectWorkItemTypesQuery, typesQuerySuccessHandler],
    ]);

    // Write the query cache only when required e.g., notification widget mutation is called
    if (writeQueryCache) {
      const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true });

      mockApollo.clients.defaultClient.cache.writeQuery({
        query: workItemByIidQuery,
        variables: { fullPath: mockFullPath, iid: mockWorkItemIid },
        data: workItemQueryResponse.data,
      });
    }

    wrapper = shallowMountExtended(WorkItemActions, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: mockApollo,
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        canUpdate,
        canDelete,
        isConfidential,
        subscribed,
        isParentConfidential,
        workItemType,
        workItemReference,
        workItemCreateNoteEmail,
        workItemIid: '1',
      },
      provide: {
        fullPath: mockFullPath,
        glFeatures: { workItemsMvc2: true },
      },
      mocks: {
        $toast,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: modalShowSpy,
          },
        }),
      },
    });
  };

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
    expect(findModal().props('visible')).toBe(false);
  });

  it('renders dropdown actions', () => {
    createComponent();

    expect(findDropdownItemsActual()).toEqual([
      {
        testId: TEST_ID_NOTIFICATIONS_TOGGLE_FORM,
        text: '',
      },
      {
        divider: true,
      },
      {
        testId: TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION,
        text: 'Turn on confidentiality',
      },
      {
        testId: TEST_ID_COPY_REFERENCE_ACTION,
        text: 'Copy reference',
      },
      {
        testId: TEST_ID_COPY_CREATE_NOTE_EMAIL_ACTION,
        text: 'Copy task email address',
      },
      {
        divider: true,
      },
      {
        testId: TEST_ID_DELETE_ACTION,
        text: 'Delete task',
      },
    ]);
  });

  describe('toggle confidentiality action', () => {
    it.each`
      isConfidential | buttonText
      ${true}        | ${'Turn off confidentiality'}
      ${false}       | ${'Turn on confidentiality'}
    `(
      'renders confidentiality toggle button with text "$buttonText"',
      ({ isConfidential, buttonText }) => {
        createComponent({ isConfidential });

        expect(findConfidentialityToggleButton().text()).toBe(buttonText);
      },
    );

    it('emits `toggleWorkItemConfidentiality` event when clicked', () => {
      createComponent();

      findConfidentialityToggleButton().vm.$emit('click');

      expect(wrapper.emitted('toggleWorkItemConfidentiality')[0]).toEqual([true]);
    });

    it.each`
      props                             | propName                  | value
      ${{ isParentConfidential: true }} | ${'isParentConfidential'} | ${true}
      ${{ canUpdate: false }}           | ${'canUpdate'}            | ${false}
    `('does not render when $propName is $value', ({ props }) => {
      createComponent(props);

      expect(findConfidentialityToggleButton().exists()).toBe(false);
    });
  });

  describe('delete action', () => {
    it('shows confirm modal when clicked', () => {
      createComponent();

      findDeleteButton().vm.$emit('click');

      expect(modalShowSpy).toHaveBeenCalled();
    });

    it('emits event when clicking OK button', () => {
      createComponent();

      findModal().vm.$emit('ok');

      expect(wrapper.emitted('deleteWorkItem')).toEqual([[]]);
    });

    it('does not render when canDelete is false', () => {
      createComponent({
        canDelete: false,
      });

      expect(findDeleteButton().exists()).toBe(false);
    });
  });

  describe('notifications action', () => {
    const errorMessage = 'Failed to subscribe';
    const notificationToggledOffMessage = 'Notifications turned off.';
    const notificationToggledOnMessage = 'Notifications turned on.';

    const toggleNotificationsOffHandler = jest.fn().mockResolvedValue({
      data: {
        updateWorkItemNotificationsSubscription: {
          issue: {
            id: 'gid://gitlab/WorkItem/1',
            subscribed: false,
          },
          errors: [],
        },
      },
    });

    const toggleNotificationsOnHandler = jest.fn().mockResolvedValue({
      data: {
        updateWorkItemNotificationsSubscription: {
          issue: {
            id: 'gid://gitlab/WorkItem/1',
            subscribed: true,
          },
          errors: [],
        },
      },
    });

    const toggleNotificationsFailureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));

    const notificationsOffMock = [
      updateWorkItemNotificationsMutation,
      toggleNotificationsOffHandler,
    ];

    const notificationsOnMock = [updateWorkItemNotificationsMutation, toggleNotificationsOnHandler];

    const notificationsFailureMock = [
      updateWorkItemNotificationsMutation,
      toggleNotificationsFailureHandler,
    ];

    beforeEach(() => {
      createComponent({ writeQueryCache: true });
      isLoggedIn.mockReturnValue(true);
    });

    it('renders toggle button', () => {
      expect(findNotificationsToggleButton().exists()).toBe(true);
    });

    it.each`
      scenario        | subscribedToNotifications | notificationsMock       | subscribedState | toastMessage
      ${'turned off'} | ${false}                  | ${notificationsOffMock} | ${false}        | ${notificationToggledOffMessage}
      ${'turned on'}  | ${true}                   | ${notificationsOnMock}  | ${true}         | ${notificationToggledOnMessage}
    `(
      'calls mutation and displays toast when notification toggle is $scenario',
      async ({ subscribedToNotifications, notificationsMock, subscribedState, toastMessage }) => {
        createComponent({ notificationsMock, writeQueryCache: true });

        await waitForPromises();

        findNotificationsToggle().vm.$emit('change', subscribedToNotifications);

        await waitForPromises();

        expect(notificationsMock[1]).toHaveBeenCalledWith({
          input: {
            projectPath: mockFullPath,
            iid: mockWorkItemIid,
            subscribedState,
          },
        });
        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    it('emits error when the update notification mutation fails', async () => {
      createComponent({ notificationsMock: notificationsFailureMock, writeQueryCache: true });

      await waitForPromises();

      findNotificationsToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
    });
  });

  describe('promote action', () => {
    it.each`
      workItemType   | show
      ${'Task'}      | ${false}
      ${'Objective'} | ${false}
    `('does not show promote button for $workItemType', ({ workItemType, show }) => {
      createComponent({ workItemType });

      expect(findPromoteButton().exists()).toBe(show);
    });

    it('promote key result to objective', async () => {
      createComponent({ workItemType: 'Key Result' });

      // wait for work item types
      await waitForPromises();

      expect(findPromoteButton().exists()).toBe(true);
      findPromoteButton().vm.$emit('click');

      await waitForPromises();

      expect(convertWorkItemMutationSuccessHandler).toHaveBeenCalled();
      expect($toast.show).toHaveBeenCalledWith('Promoted to objective.');
      expect(wrapper.emitted('promotedToObjective')).toEqual([[]]);
    });

    it('emits error when promote mutation fails', async () => {
      createComponent({
        workItemType: 'Key Result',
        convertWorkItemMutationHandler: convertWorkItemMutationErrorHandler,
      });

      // wait for work item types
      await waitForPromises();

      expect(findPromoteButton().exists()).toBe(true);
      findPromoteButton().vm.$emit('click');

      await waitForPromises();

      expect(convertWorkItemMutationErrorHandler).toHaveBeenCalled();
      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while promoting the key result. Please try again.'],
      ]);
    });
  });

  describe('copy reference action', () => {
    it('shows toast when user clicks on the action', () => {
      createComponent();

      expect(findCopyReferenceButton().exists()).toBe(true);
      findCopyReferenceButton().vm.$emit('click');

      expect(toast).toHaveBeenCalledWith('Reference copied');
    });
  });

  describe('copy email address action', () => {
    it.each(['key result', 'objective'])(
      'renders correct button name when work item is %s',
      (workItemType) => {
        createComponent({ workItemType });

        expect(findCopyCreateNoteEmailButton().text()).toEqual(
          `Copy ${workItemType} email address`,
        );
      },
    );

    it('shows toast when user clicks on the action', () => {
      createComponent();

      expect(findCopyCreateNoteEmailButton().exists()).toBe(true);
      findCopyCreateNoteEmailButton().vm.$emit('click');

      expect(toast).toHaveBeenCalledWith('Email address copied');
    });
  });
});
