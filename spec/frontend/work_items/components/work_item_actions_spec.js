import { GlDropdownDivider, GlModal, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
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
} from '~/work_items/constants';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import convertWorkItemMutation from '~/work_items/graphql/work_item_convert.mutation.graphql';
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
  let glModalDirective;
  let mockApollo;

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId(TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION);
  const findNotificationsToggleButton = () =>
    wrapper.findByTestId(TEST_ID_NOTIFICATIONS_TOGGLE_ACTION);
  const findDeleteButton = () => wrapper.findByTestId(TEST_ID_DELETE_ACTION);
  const findPromoteButton = () => wrapper.findByTestId(TEST_ID_PROMOTE_ACTION);
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
  } = {}) => {
    const handlers = [notificationsMock];
    glModalDirective = jest.fn();
    mockApollo = createMockApollo([
      ...handlers,
      [convertWorkItemMutation, convertWorkItemMutationHandler],
      [projectWorkItemTypesQuery, typesQuerySuccessHandler],
    ]);
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
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      provide: {
        fullPath: 'gitlab-org/gitlab',
        glFeatures: { workItemsMvc2: true },
      },
      mocks: {
        $toast,
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

      expect(glModalDirective).toHaveBeenCalled();
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
    const id = 'gid://gitlab/WorkItem/1';
    const notificationToggledOffMessage = 'Notifications turned off.';
    const notificationToggledOnMessage = 'Notifications turned on.';

    const inputVariablesOff = {
      id,
      notificationsWidget: {
        subscribed: false,
      },
    };

    const inputVariablesOn = {
      id,
      notificationsWidget: {
        subscribed: true,
      },
    };

    const notificationsOffExpectedResponse = workItemByIidResponseFactory({
      subscribed: false,
    });

    const toggleNotificationsOffHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: notificationsOffExpectedResponse.data.workspace.workItems.nodes[0],
          errors: [],
        },
      },
    });

    const notificationsOnExpectedResponse = workItemByIidResponseFactory({
      subscribed: true,
    });

    const toggleNotificationsOnHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: notificationsOnExpectedResponse.data.workspace.workItems.nodes[0],
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
      createComponent();
      isLoggedIn.mockReturnValue(true);
    });

    it('renders toggle button', () => {
      expect(findNotificationsToggleButton().exists()).toBe(true);
    });

    it.each`
      scenario        | subscribedToNotifications | notificationsMock       | inputVariables       | toastMessage
      ${'turned off'} | ${false}                  | ${notificationsOffMock} | ${inputVariablesOff} | ${notificationToggledOffMessage}
      ${'turned on'}  | ${true}                   | ${notificationsOnMock}  | ${inputVariablesOn}  | ${notificationToggledOnMessage}
    `(
      'calls mutation and displays toast when notification toggle is $scenario',
      async ({ subscribedToNotifications, notificationsMock, inputVariables, toastMessage }) => {
        createComponent({ notificationsMock });

        await waitForPromises();

        findNotificationsToggle().vm.$emit('change', subscribedToNotifications);

        await waitForPromises();

        expect(notificationsMock[1]).toHaveBeenCalledWith({
          input: inputVariables,
        });
        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    it('emits error when the update notification mutation fails', async () => {
      createComponent({ notificationsMock: notificationsFailureMock });

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
});
