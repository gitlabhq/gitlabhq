import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { refreshCurrentPageWithAlerts } from '~/lib/utils/url_utility';
import showToast from '~/vue_shared/plugins/global_toast';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from '~/admin/users/components/modals/remove_from_organization_modal_event_hub';
import RemoveOrganizationUserModal from '~/admin/users/components/modals/remove_organization_user_modal.vue';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';
import ModalStub from './stubs/modal_stub';

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

  const successHandler = jest
    .fn()
    .mockResolvedValue({ data: { organizationUserDelete: { errors: [] } } });

  const findModal = () => wrapper.findComponent(ModalStub);

  const emitOpenModalEvent = () =>
    eventHub.$emit(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
      username,
      organizationUserGid,
    });

  const createComponent = (handler = successHandler) => {
    wrapper = shallowMountExtended(RemoveOrganizationUserModal, {
      apolloProvider: createMockApollo([[removeOrganizationUserMutation, handler]]),
      stubs: { GlModal: ModalStub },
    });
  };

  it('shows the modal when the open event is emitted', async () => {
    createComponent();

    await emitOpenModalEvent();

    expect(findModal().vm.showWasCalled).toBe(true);
  });

  describe('when the modal is confirmed', () => {
    it('calls the mutation with the organization user GID and refreshes with a success alert', async () => {
      createComponent();
      await emitOpenModalEvent();

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

    describe('when the mutation returns errors', () => {
      const errorHandler = jest.fn().mockResolvedValue({
        data: { organizationUserDelete: { errors: ['Something went wrong'] } },
      });

      it('hides the modal, shows a toast, and does not refresh the page', async () => {
        createComponent(errorHandler);
        await emitOpenModalEvent();

        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();

        expect(findModal().vm.hideWasCalled).toBe(true);
        expect(showToast).toHaveBeenCalledWith('Something went wrong');
        expect(refreshCurrentPageWithAlerts).not.toHaveBeenCalled();
      });
    });

    describe('when the mutation request fails', () => {
      const failHandler = jest.fn().mockRejectedValue(new Error('Network error'));

      it('hides the modal and shows a generic toast', async () => {
        createComponent(failHandler);
        await emitOpenModalEvent();

        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();

        expect(findModal().vm.hideWasCalled).toBe(true);
        expect(showToast).toHaveBeenCalledWith(
          'An error occurred while removing the user from the organization.',
        );
        expect(refreshCurrentPageWithAlerts).not.toHaveBeenCalled();
      });
    });
  });
});
