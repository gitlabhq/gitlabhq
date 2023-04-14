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
} from '~/work_items/constants';
import updateWorkItemNotificationsMutation from '~/work_items/graphql/update_work_item_notifications.mutation.graphql';
import { workItemResponseFactory } from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/vue_shared/plugins/global_toast');

describe('WorkItemActions component', () => {
  Vue.use(VueApollo);

  let wrapper;
  let glModalDirective;

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfidentialityToggleButton = () =>
    wrapper.findByTestId(TEST_ID_CONFIDENTIALITY_TOGGLE_ACTION);
  const findNotificationsToggleButton = () =>
    wrapper.findByTestId(TEST_ID_NOTIFICATIONS_TOGGLE_ACTION);
  const findDeleteButton = () => wrapper.findByTestId(TEST_ID_DELETE_ACTION);
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

  const createComponent = ({
    canUpdate = true,
    canDelete = true,
    isConfidential = false,
    subscribed = false,
    isParentConfidential = false,
    notificationsMock = [updateWorkItemNotificationsMutation, jest.fn()],
  } = {}) => {
    const handlers = [notificationsMock];
    glModalDirective = jest.fn();
    wrapper = shallowMountExtended(WorkItemActions, {
      apolloProvider: createMockApollo(handlers),
      isLoggedIn: isLoggedIn(),
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        canUpdate,
        canDelete,
        isConfidential,
        subscribed,
        isParentConfidential,
        workItemType: 'Task',
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
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
    const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
    const inputVariables = {
      id: workItemQueryResponse.data.workItem.id,
      notificationsWidget: {
        subscribed: false,
      },
    };

    const notificationExpectedResponse = workItemResponseFactory({
      subscribed: false,
    });

    const toggleNotificationsHandler = jest.fn().mockResolvedValue({
      data: {
        workItemUpdate: {
          workItem: notificationExpectedResponse.data.workItem,
          errors: [],
        },
      },
    });

    const errorMessage = 'Failed to subscribe';
    const toggleNotificationsFailureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));

    const notificationsMock = [updateWorkItemNotificationsMutation, toggleNotificationsHandler];

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

    it('calls notification mutation and displays a toast when the notification widget is toggled', async () => {
      createComponent({ notificationsMock });

      await waitForPromises();

      findNotificationsToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(notificationsMock[1]).toHaveBeenCalledWith({
        input: inputVariables,
      });
      expect(toast).toHaveBeenCalledWith('Notifications turned off.');
    });

    it('emits error when the update notification mutation fails', async () => {
      createComponent({ notificationsMock: notificationsFailureMock });

      await waitForPromises();

      findNotificationsToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
    });
  });
});
