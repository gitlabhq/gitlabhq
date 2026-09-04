import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import LeaveOrganizationModal from '~/organizations/show/components/leave_organization_modal.vue';
import organizationUserDeleteMutation from '~/organizations/show/graphql/mutations/organization_user_delete.mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

describe('LeaveOrganizationModal', () => {
  let wrapper;
  let mockApollo;

  const organizationUserGid = 'gid://gitlab/Organizations::OrganizationUser/1';

  const defaultPropsData = {
    visible: true,
    modalId: 'leave-organization-modal',
    organization: { name: 'GitLab', path: 'gitlab' },
    organizationUserGid,
  };

  const successHandler = jest
    .fn()
    .mockResolvedValue({ data: { organizationUserDelete: { errors: [] } } });

  const createComponent = ({ handler = successHandler } = {}) => {
    mockApollo = createMockApollo([[organizationUserDeleteMutation, handler]]);

    wrapper = shallowMountExtended(LeaveOrganizationModal, {
      propsData: defaultPropsData,
      apolloProvider: mockApollo,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const submitModal = () => findModal().vm.$emit('primary', { preventDefault: jest.fn() });

  afterEach(() => {
    mockApollo = null;
  });

  it('renders the modal with the confirmation title', () => {
    createComponent();

    expect(findModal().props('title')).toBe('Are you sure you want to leave "GitLab"?');
  });

  describe('when the mutation succeeds', () => {
    beforeEach(async () => {
      createComponent();
      submitModal();
      await waitForPromises();
    });

    it('calls the mutation with the organization user gid', () => {
      expect(successHandler).toHaveBeenCalledWith({
        input: { id: organizationUserGid },
      });
    });

    it('redirects with a success alert', () => {
      expect(visitUrlWithAlerts).toHaveBeenCalledWith('/', [
        expect.objectContaining({
          id: 'organization-left-successfully',
          message: 'You left the "GitLab" organization.',
        }),
      ]);
    });
  });

  describe('when the mutation returns errors', () => {
    beforeEach(async () => {
      createComponent({
        handler: jest
          .fn()
          .mockResolvedValue({ data: { organizationUserDelete: { errors: ['Nope'] } } }),
      });
      submitModal();
      await waitForPromises();
    });

    it('creates an alert with the generic error message', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'An error occurred while leaving the organization.',
          captureError: true,
        }),
      );
    });

    it('does not redirect', () => {
      expect(visitUrlWithAlerts).not.toHaveBeenCalled();
    });
  });

  describe('when the mutation throws an error', () => {
    beforeEach(async () => {
      createComponent({ handler: jest.fn().mockRejectedValue(new Error('network')) });
      submitModal();
      await waitForPromises();
    });

    it('creates an alert', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'An error occurred while leaving the organization.',
          captureError: true,
        }),
      );
    });
  });
});
