import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlAlert, GlFormSelect, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import AddOrganizationUsersModal from '~/organizations/admin/components/add_organization_users_modal.vue';
import OrganizationUsersTokenSelect from '~/organizations/admin/components/organization_users_token_select.vue';
import organizationUserCreateMutation from '~/organizations/admin/graphql/mutations/organization_user_create.mutation.graphql';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('AddOrganizationUsersModal', () => {
  let wrapper;

  const organizationGid = 'gid://gitlab/Organizations::Organization/1';
  const organizationName = 'My organization';

  const successResponse = {
    data: {
      organizationUserCreate: {
        errors: [],
      },
    },
  };

  const errorResponse = {
    data: {
      organizationUserCreate: {
        errors: ['The user could not be found'],
      },
    },
  };

  const mockToastShow = jest.fn();

  const createComponent = ({
    mutationHandler = jest.fn().mockResolvedValue(successResponse),
  } = {}) => {
    const apolloProvider = createMockApollo([[organizationUserCreateMutation, mutationHandler]]);

    wrapper = shallowMountExtended(AddOrganizationUsersModal, {
      apolloProvider,
      provide: { organizationGid, organizationName },
      propsData: { visible: true },
      stubs: { GlSprintf },
      mocks: { $toast: { show: mockToastShow } },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findTokenSelect = () => wrapper.findComponent(OrganizationUsersTokenSelect);
  const findRoleSelect = () => wrapper.findComponent(GlFormSelect);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const selectTokens = (tokens) => findTokenSelect().vm.$emit('input', tokens);
  const selectRole = (userType) => findRoleSelect().vm.$emit('input', userType);
  const submit = () => findModal().vm.$emit('primary', { preventDefault: jest.fn() });

  it('renders a modal with a token select and a role select', () => {
    createComponent();

    expect(findModal().props('visible')).toBe(true);
    expect(findTokenSelect().exists()).toBe(true);
    expect(findRoleSelect().exists()).toBe(true);
  });

  it('sets Invite as the primary action text', () => {
    createComponent();

    expect(findModal().props('actionPrimary').text).toBe('Invite');
  });

  it('renders the organization name in the description', () => {
    createComponent();

    expect(wrapper.findByTestId('modal-description').text()).toBe(
      `You're inviting users to the ${organizationName} organization.`,
    );
  });

  it('defaults the role select to USER', () => {
    createComponent();

    expect(findRoleSelect().attributes('value')).toBe('USER');
  });

  describe('when submitting with selected users', () => {
    it('calls the mutation once per token with username or email', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(successResponse);
      createComponent({ mutationHandler });

      selectTokens([
        { id: 1, username: 'user1' },
        { id: 2, name: 'new@example.com' },
      ]);
      submit();
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledTimes(2);
      expect(mutationHandler).toHaveBeenCalledWith({
        input: { organizationId: organizationGid, userType: 'USER', username: 'user1' },
      });
      expect(mutationHandler).toHaveBeenCalledWith({
        input: { organizationId: organizationGid, userType: 'USER', email: 'new@example.com' },
      });
    });

    it('sends the selected role as userType', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(successResponse);
      createComponent({ mutationHandler });

      selectRole('ADMIN');
      selectTokens([{ id: 1, username: 'user1' }]);
      submit();
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        input: { organizationId: organizationGid, userType: 'ADMIN', username: 'user1' },
      });
    });

    it('shows a success toast and closes without reloading on success', async () => {
      createComponent();

      selectTokens([{ id: 1, username: 'user1' }]);
      submit();
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toContainEqual([false]);
    });
  });

  describe('when the mutation returns errors', () => {
    it('displays the error associated with the user and keeps the modal open', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(errorResponse);
      createComponent({ mutationHandler });

      selectTokens([{ id: 1, username: 'user1' }]);
      submit();
      await waitForPromises();

      expect(findAlert().text()).toContain('user1: The user could not be found');
      expect(wrapper.emitted('change')).toBeUndefined();
    });

    it('associates each error with the correct user on partial failure', async () => {
      const mutationHandler = jest
        .fn()
        .mockResolvedValueOnce(successResponse)
        .mockResolvedValueOnce(errorResponse);
      createComponent({ mutationHandler });

      selectTokens([
        { id: 1, username: 'user1' },
        { id: 2, name: 'bad@example.com' },
      ]);
      submit();
      await waitForPromises();

      const alertText = findAlert().text();
      expect(alertText).toContain('bad@example.com: The user could not be found');
      expect(alertText).not.toContain('user1');
    });

    it('shows a partial-success warning alert and keeps the modal open when some invites succeed', async () => {
      const mutationHandler = jest
        .fn()
        .mockResolvedValueOnce(successResponse)
        .mockResolvedValueOnce(errorResponse);
      createComponent({ mutationHandler });

      selectTokens([
        { id: 1, username: 'user1' },
        { id: 2, name: 'bad@example.com' },
      ]);
      submit();
      await waitForPromises();

      expect(findAlert().props('variant')).toBe('warning');
      expect(findAlert().props('title')).toBe('1 of 2 users invited.');
      expect(wrapper.emitted('change')).toBeUndefined();
    });

    it('keeps only the failed tokens selected after a partial failure', async () => {
      const mutationHandler = jest
        .fn()
        .mockResolvedValueOnce(successResponse)
        .mockResolvedValueOnce(errorResponse);
      createComponent({ mutationHandler });

      const failedToken = { id: 2, name: 'bad@example.com' };
      selectTokens([{ id: 1, username: 'user1' }, failedToken]);
      submit();
      await waitForPromises();

      expect(findTokenSelect().props('selectedTokens')).toEqual([failedToken]);
    });

    it('shows a danger alert with a failure title when every invite fails', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(errorResponse);
      createComponent({ mutationHandler });

      selectTokens([{ id: 1, name: 'bad@example.com' }]);
      submit();
      await waitForPromises();

      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().props('title')).toBe('The following users could not be invited:');
    });

    it('shows a separate error for each failing user', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(errorResponse);
      createComponent({ mutationHandler });

      selectTokens([
        { id: 1, name: 'bad1@example.com' },
        { id: 2, name: 'bad2@example.com' },
      ]);
      submit();
      await waitForPromises();

      const alertText = findAlert().text();
      expect(mutationHandler).toHaveBeenCalledTimes(2);
      expect(alertText).toContain('bad1@example.com: The user could not be found');
      expect(alertText).toContain('bad2@example.com: The user could not be found');
    });
  });

  describe('when a token has neither a username nor a valid email', () => {
    it('shows a validation error without calling the mutation or Sentry', async () => {
      const mutationHandler = jest.fn().mockResolvedValue(successResponse);
      createComponent({ mutationHandler });

      selectTokens([{ id: 1, name: 'not-an-email' }]);
      submit();
      await waitForPromises();

      expect(mutationHandler).not.toHaveBeenCalled();
      expect(Sentry.captureException).not.toHaveBeenCalled();
      expect(findAlert().text()).toContain(
        'not-an-email: Enter an email address or GitLab username.',
      );
      expect(wrapper.emitted('change')).toBeUndefined();
    });
  });

  describe('when the mutation request fails', () => {
    it('captures the exception and shows an error', async () => {
      const mutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));
      createComponent({ mutationHandler });

      selectTokens([{ id: 1, username: 'user1' }]);
      submit();
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findAlert().exists()).toBe(true);
    });
  });

  it('resets and closes on cancel', () => {
    createComponent();

    findModal().vm.$emit('canceled');

    expect(wrapper.emitted('change')).toContainEqual([false]);
  });
});
