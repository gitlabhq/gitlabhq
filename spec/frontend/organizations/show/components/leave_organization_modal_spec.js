import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { setCurrentUser } from 'helpers/current_user_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import LeaveOrganizationModal from '~/organizations/show/components/leave_organization_modal.vue';
import SoloOwnedGroupsList from '~/organizations/shared/components/solo_owned_groups_list.vue';
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
      stubs: {
        SoloOwnedGroupsList: stubComponent(SoloOwnedGroupsList, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSoloOwnedGroupsList = () => wrapper.findComponent(SoloOwnedGroupsList);
  const findSoloOwnedGroupsHelp = () => wrapper.findByTestId('slot-help');
  const submitModal = () => findModal().vm.$emit('primary', { preventDefault: jest.fn() });
  const emitSoloOwnedGroupsChange = (status) =>
    findSoloOwnedGroupsList().vm.$emit('change', { loading: false, error: false, ...status });

  beforeEach(() => {
    setCurrentUser({ id: 7 });
  });

  afterEach(() => {
    mockApollo = null;
  });

  it('renders the modal with the confirmation title', () => {
    createComponent();

    expect(findModal().props('title')).toBe('Are you sure you want to leave "GitLab"?');
  });

  it('renders the solo-owned groups list for the current user', () => {
    createComponent();

    expect(findSoloOwnedGroupsList().props('userId')).toBe(7);
  });

  describe('while solo-owned groups are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('disables the leave button', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });

    it('does not render the leave consequences', () => {
      expect(wrapper.text()).not.toContain('When you leave this organization:');
    });
  });

  describe('when solo-owned groups fail to load', () => {
    beforeEach(async () => {
      createComponent();
      await emitSoloOwnedGroupsChange({ count: 0, error: true });
    });

    it('disables the leave button', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });

    it('does not render the leave consequences', () => {
      expect(wrapper.text()).not.toContain('When you leave this organization:');
    });
  });

  describe('when the user is the sole owner of groups', () => {
    beforeEach(async () => {
      createComponent();
      await emitSoloOwnedGroupsChange({ count: 3 });
    });

    it('renders the help text', () => {
      expect(findSoloOwnedGroupsHelp().text()).toBe(
        "To leave the organization, assign another owner to each group above. Your account isn't deleted.",
      );
    });

    it('disables the leave button', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
    });

    it('does not render the leave consequences', () => {
      expect(wrapper.text()).not.toContain('When you leave this organization:');
    });
  });

  describe('when the user is not the sole owner of any group', () => {
    beforeEach(async () => {
      createComponent();
      await emitSoloOwnedGroupsChange({ count: 0 });
    });

    it('enables the leave button', () => {
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });

    it('renders the leave consequences', () => {
      expect(wrapper.text()).toContain('When you leave this organization:');
    });
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
          message: 'An error occurred while leaving the organization. Please try again.',
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
          message: 'An error occurred while leaving the organization. Please try again.',
          captureError: true,
        }),
      );
    });
  });
});
