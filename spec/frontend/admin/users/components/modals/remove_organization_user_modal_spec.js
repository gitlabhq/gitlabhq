import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { refreshCurrentPageWithAlerts } from '~/lib/utils/url_utility';
import showToast from '~/vue_shared/plugins/global_toast';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from '~/admin/users/components/modals/remove_from_organization_modal_event_hub';
import RemoveOrganizationUserModal from '~/admin/users/components/modals/remove_organization_user_modal.vue';
import SoloOwnedGroupsList from '~/organizations/shared/components/solo_owned_groups_list.vue';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  refreshCurrentPageWithAlerts: jest.fn(),
}));
jest.mock('~/vue_shared/plugins/global_toast');

Vue.use(VueApollo);

describe('RemoveOrganizationUserModal', () => {
  let wrapper;

  const organizationUserGid = 'gid://gitlab/Organizations::OrganizationUser/1';
  const username = 'John Doe';
  const userId = 1;

  const successHandler = jest
    .fn()
    .mockResolvedValue({ data: { organizationUserDelete: { errors: [] } } });

  const mockShowModal = jest.fn();
  const mockHideModal = jest.fn();

  const findModal = () => wrapper.findComponent(GlModal);
  const findPrimaryLoading = () => findModal().props('actionPrimary').attributes.loading;
  const findPrimaryDisabled = () => findModal().props('actionPrimary').attributes.disabled;
  const findSoloOwnedGroupsList = () => wrapper.findComponent(SoloOwnedGroupsList);
  const findSoloOwnedGroupsHelp = () => wrapper.findByTestId('slot-help');

  const emitOpenModalEvent = (overrides = {}) =>
    eventHub.$emit(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
      username,
      userId,
      organizationUserGid,
      ...overrides,
    });

  const emitSoloOwnedGroupsStatus = (status) =>
    findSoloOwnedGroupsList().vm.$emit('change', status);

  const openModalWithSoloOwnedGroups = async (
    status = { loading: false, count: 0, error: false },
  ) => {
    await emitOpenModalEvent();
    await emitSoloOwnedGroupsStatus(status);
  };

  const createComponent = (handler = successHandler) => {
    wrapper = shallowMountExtended(RemoveOrganizationUserModal, {
      apolloProvider: createMockApollo([[removeOrganizationUserMutation, handler]]),
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
          methods: { show: mockShowModal, hide: mockHideModal },
        }),
        GlSprintf,
        SoloOwnedGroupsList: stubComponent(SoloOwnedGroupsList, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  it('shows the modal when the open event is emitted', async () => {
    createComponent();

    await emitOpenModalEvent();

    expect(mockShowModal).toHaveBeenCalled();
  });

  it('renders the title with the username', async () => {
    createComponent();

    await emitOpenModalEvent();

    expect(findModal().props('title')).toBe('Remove user John Doe');
  });

  it('does not escape special characters in the title', async () => {
    createComponent();

    await emitOpenModalEvent({ username: 'Tom & Jerry' });

    expect(findModal().props('title')).toBe('Remove user Tom & Jerry');
  });

  it('renders the primary button text', async () => {
    createComponent();

    await emitOpenModalEvent();

    expect(findModal().props('actionPrimary').text).toBe('Remove user');
  });

  it('renders the solo owned groups list for the user', async () => {
    createComponent();

    await emitOpenModalEvent();

    expect(findSoloOwnedGroupsList().props()).toMatchObject({ userId, username });
  });

  describe.each`
    state                          | status
    ${'while loading groups'}      | ${{ loading: true, count: 0, error: false }}
    ${'when loading groups fails'} | ${{ loading: false, count: 0, error: true }}
  `('$state', ({ status }) => {
    beforeEach(async () => {
      createComponent();
      await openModalWithSoloOwnedGroups(status);
    });

    it('disables the remove button', () => {
      expect(findPrimaryDisabled()).toBe(true);
    });

    it('does not render the confirmation message', () => {
      expect(wrapper.text()).not.toContain('You are about to remove');
    });
  });

  describe('when the user is the sole owner of groups', () => {
    beforeEach(async () => {
      createComponent();
      await openModalWithSoloOwnedGroups({ loading: false, count: 7, error: false });
    });

    it('renders the help message explaining how to unblock the removal', () => {
      expect(findSoloOwnedGroupsHelp().text()).toBe(
        "To remove John Doe from the organization, assign another owner to each group above. Their account isn't deleted.",
      );
    });

    it('disables the remove button', () => {
      expect(findPrimaryDisabled()).toBe(true);
    });
  });

  describe('when the user is not the sole owner of any group', () => {
    beforeEach(async () => {
      createComponent();
      await openModalWithSoloOwnedGroups();
    });

    it('renders the confirmation message', () => {
      expect(wrapper.text()).toContain('You are about to remove John Doe from the organization.');
    });

    it('enables the remove button', () => {
      expect(findPrimaryDisabled()).toBe(false);
    });
  });

  describe('when the modal is reopened', () => {
    beforeEach(async () => {
      createComponent();
      await openModalWithSoloOwnedGroups();
    });

    describe('for another user', () => {
      const otherUserId = 2;

      beforeEach(async () => {
        await emitOpenModalEvent({ username: 'Jane Doe', userId: otherUserId });
      });

      it('disables the remove button until the solo owned groups of that user are loaded', async () => {
        expect(findPrimaryDisabled()).toBe(true);

        await emitSoloOwnedGroupsStatus({ loading: false, count: 0, error: false });

        expect(findPrimaryDisabled()).toBe(false);
      });

      it('renders the solo owned groups list for that user', () => {
        expect(findSoloOwnedGroupsList().props('userId')).toBe(otherUserId);
      });
    });

    describe('for the same user', () => {
      it('keeps the remove button enabled', async () => {
        await emitOpenModalEvent();

        expect(findPrimaryDisabled()).toBe(false);
      });
    });
  });

  describe('when the modal is confirmed', () => {
    it('calls the mutation with the organization user GID and refreshes with a success alert', async () => {
      createComponent();
      await openModalWithSoloOwnedGroups();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({ id: organizationUserGid });
      expect(refreshCurrentPageWithAlerts).toHaveBeenCalledWith([
        {
          id: 'organization-user-removed',
          message: 'User was successfully removed from the organization.',
          variant: 'success',
        },
      ]);
      expect(showToast).not.toHaveBeenCalled();
    });

    it('keeps the primary button loading until the redirect completes', async () => {
      createComponent();
      await openModalWithSoloOwnedGroups();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(findPrimaryLoading()).toBe(true);
    });

    describe('when the mutation returns errors', () => {
      const errorHandler = jest.fn().mockResolvedValue({
        data: { organizationUserDelete: { errors: ['Something went wrong'] } },
      });

      it('hides the modal, shows a toast, and does not refresh the page', async () => {
        createComponent(errorHandler);
        await openModalWithSoloOwnedGroups();

        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();

        expect(mockHideModal).toHaveBeenCalled();
        expect(showToast).toHaveBeenCalledWith('Something went wrong');
        expect(refreshCurrentPageWithAlerts).not.toHaveBeenCalled();
        expect(findPrimaryLoading()).toBe(false);
      });
    });

    describe('when the mutation request fails', () => {
      const failHandler = jest.fn().mockRejectedValue(new Error('Network error'));

      it('hides the modal and shows a generic toast', async () => {
        createComponent(failHandler);
        await openModalWithSoloOwnedGroups();

        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();

        expect(mockHideModal).toHaveBeenCalled();
        expect(showToast).toHaveBeenCalledWith(
          'An error occurred while removing the user from the organization. Please try again.',
        );
        expect(refreshCurrentPageWithAlerts).not.toHaveBeenCalled();
        expect(findPrimaryLoading()).toBe(false);
      });
    });
  });
});
