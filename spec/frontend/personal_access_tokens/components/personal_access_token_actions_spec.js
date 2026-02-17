import { GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import PersonalAccessTokenActions from '~/personal_access_tokens/components/personal_access_token_actions.vue';
import getUserPersonalAccessTokens from '~/personal_access_tokens/graphql/get_user_personal_access_tokens.query.graphql';
import getUserPersonalAccessTokenStatistics from '~/personal_access_tokens/graphql/get_user_personal_access_token_statistics.query.graphql';
import revokePersonalAccessToken from '~/personal_access_tokens/graphql/revoke_personal_access_token.mutation.graphql';
import rotatePersonalAccessToken from '~/personal_access_tokens/graphql/rotate_personal_access_token.mutation.graphql';
import {
  mockTokens,
  mockRotateMutationResponse,
  mockRevokeMutationResponse,
  mockQueryResponse,
  mockStatisticsResponse,
} from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('PersonalAccessTokenActions', () => {
  let wrapper;
  let mockApollo;

  const tokenValue = 'xx';
  const mockToken = mockTokens[0];
  const mockAction = 'rotate';

  const mockRotateHandler = jest.fn().mockResolvedValue(mockRotateMutationResponse);
  const mockRevokeHandler = jest.fn().mockResolvedValue(mockRevokeMutationResponse);

  const mockTokensHandler = jest.fn().mockResolvedValue(mockQueryResponse);
  const mockStatisticsHandler = jest.fn().mockResolvedValue(mockStatisticsResponse);

  const createComponent = ({
    token = mockToken,
    action = mockAction,
    rotateHandler = mockRotateHandler,
    revokeHandler = mockRevokeHandler,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [rotatePersonalAccessToken, rotateHandler],
        [revokePersonalAccessToken, revokeHandler],
        [getUserPersonalAccessTokens, mockTokensHandler],
        [getUserPersonalAccessTokenStatistics, mockStatisticsHandler],
      ],
      {},
      { typePolicies: { Query: { fields: { user: { merge: true } } } } },
    );

    mockApollo.clients.defaultClient
      .watchQuery({
        query: getUserPersonalAccessTokens,
      })
      .subscribe();

    mockApollo.clients.defaultClient
      .watchQuery({
        query: getUserPersonalAccessTokenStatistics,
      })
      .subscribe();

    wrapper = shallowMountExtended(PersonalAccessTokenActions, {
      apolloProvider: mockApollo,
      propsData: {
        token,
        action,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalActionPrimary = () => findModal().props('actionPrimary');

  beforeEach(() => {
    createComponent();
  });

  it('shows modal when token is provided', () => {
    expect(findModal().props('visible')).toBe(true);
  });

  it('does not show modal when no token is provided', () => {
    createComponent({ token: null });

    expect(findModal().props('visible')).toBe(false);
  });

  it('emits close event when modal is canceled', async () => {
    await findModal().vm.$emit('canceled');

    expect(wrapper.emitted('close')).toEqual([[]]);
  });

  it('emits close event when modal is hidden', async () => {
    await findModal().vm.$emit('hidden');

    expect(wrapper.emitted('close')).toEqual([[]]);
  });

  it('shows loading state when primary button is clicked', async () => {
    await findModal().vm.$emit('primary', { preventDefault: jest.fn() });

    expect(findModalActionPrimary()).toMatchObject({
      attributes: { loading: true },
    });
  });

  describe('token revocation', () => {
    beforeEach(() => {
      createComponent({ action: 'revoke' });
    });

    it('displays correct title for revoke action', () => {
      expect(findModal().attributes('title')).toBe("Revoke the token 'Token 1'?");
    });

    it('displays correct primary button for revoke action', () => {
      expect(findModalActionPrimary()).toMatchObject({
        text: 'Revoke',
        attributes: { variant: 'danger', loading: false },
      });
    });

    it('displays correct description for revoke action', () => {
      expect(findModal().text()).toContain(
        'Are you sure you want to revoke the token Token 1? This action cannot be undone. Any tools that rely on this token will no longer have access to GitLab.',
      );
    });

    it('calls revoke mutation with correct variables', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(mockRevokeHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/PersonalAccessToken/1',
      });
    });

    it('refetches both tokens list and statistics queries after successful revocation', async () => {
      mockTokensHandler.mockClear();
      mockStatisticsHandler.mockClear();

      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(mockTokensHandler).toHaveBeenCalledTimes(1);
      expect(mockStatisticsHandler).toHaveBeenCalledTimes(1);
    });

    it('displays success alert after successful revocation', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'The token was revoked successfully.',
        variant: VARIANT_SUCCESS,
      });
    });

    it('emits `revoked` event and closes modal on successful revocation', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(wrapper.emitted('revoked')).toHaveLength(1);
      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('displays an error alert and closes modal on error', async () => {
      const mutationError = jest.fn().mockRejectedValue(new Error('Error'));

      createComponent({ action: 'revoke', revokeHandler: mutationError });

      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token revocation unsuccessful. Please try again.',
        captureError: true,
        error: expect.any(Error),
      });

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });

  describe('token rotation', () => {
    beforeEach(() => {
      createComponent({ action: 'rotate' });
    });

    it('displays correct title for rotate action', () => {
      expect(findModal().attributes('title')).toBe("Rotate the token 'Token 1'?");
    });

    it('displays correct primary button for rotate action', () => {
      expect(findModalActionPrimary()).toMatchObject({
        text: 'Rotate',
        attributes: { variant: 'confirm', loading: false },
      });
    });

    it('displays correct description for rotate action', () => {
      expect(findModal().text()).toContain(
        'Are you sure you want to rotate the token Token 1? This action cannot be undone. Any tools that rely on this token will no longer have access to GitLab.',
      );
    });

    it('calls rotate mutation with correct variables', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(mockRotateHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/PersonalAccessToken/1',
      });
    });

    it('emits `rotated` event and closes modal on successful rotation', async () => {
      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(wrapper.emitted('rotated')).toEqual([[tokenValue]]);
      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('refetches tokens list after successful rotation', async () => {
      mockTokensHandler.mockClear();

      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(mockTokensHandler).toHaveBeenCalledTimes(1);
    });

    it('displays an error alert and closes modal on error', async () => {
      const mutationError = jest.fn().mockRejectedValue(new Error('Error'));

      createComponent({ action: 'rotate', rotateHandler: mutationError });

      await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token rotation unsuccessful. Please try again.',
        captureError: true,
        error: expect.any(Error),
      });

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });
});
