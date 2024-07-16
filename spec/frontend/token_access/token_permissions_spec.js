import { GlButton, GlFormCheckbox, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import TokenPermissions from '~/token_access/components/token_permissions.vue';
import updateCiJobTokenPermissionsMutation from '~/token_access/graphql/mutations/update_ci_job_token_permissions.mutation.graphql';
import getCiJobTokenPermissionsQuery from '~/token_access/graphql/queries/get_ci_job_token_permissions.query.graphql';
import { mockPermissionsQueryResponse, mockPermissionsMutationResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('TokenPermissions component', () => {
  let wrapper;
  const mockQuery = jest.fn();
  const mockMutation = jest.fn();
  const mockToastShow = jest.fn();
  const fullPath = 'root/my-repo';

  const findButton = () => wrapper.findComponent(GlButton);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = () => {
    const handlers = [
      [getCiJobTokenPermissionsQuery, mockQuery],
      [updateCiJobTokenPermissionsMutation, mockMutation],
    ];

    wrapper = shallowMountExtended(TokenPermissions, {
      provide: {
        fullPath,
      },
      apolloProvider: createMockApollo(handlers),
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const updateCheckbox = (value) => {
    findCheckbox().vm.$emit('input', value);
    findButton().vm.$emit('click');
  };

  beforeEach(() => {
    mockQuery.mockResolvedValue(mockPermissionsQueryResponse());
    mockMutation.mockResolvedValue(mockPermissionsMutationResponse());
  });

  describe('while waiting for query to resolve', () => {
    it('shows loading state', async () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when query is not successful', () => {
    beforeEach(async () => {
      mockQuery.mockRejectedValue();

      createComponent();
      await waitForPromises();
    });

    it('does not show the loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the alert message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the CI/CD job token permissions.',
      });
    });
  });

  describe('when query is successful', () => {
    it('does not show the loading state or the alert message', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('renders checked checkbox when data returns true', async () => {
      mockQuery.mockResolvedValue(mockPermissionsQueryResponse(true));
      createComponent();
      await waitForPromises();

      expect(findCheckbox().attributes('checked')).toBeDefined();
    });

    it('renders unchecked checkbox when data returns false', async () => {
      mockQuery.mockResolvedValue(mockPermissionsQueryResponse(false));
      createComponent();
      await waitForPromises();

      expect(findCheckbox().attributes('checked')).toBeUndefined();
    });
  });

  describe('when updating allowPushToRepo', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders loading icon in button while mutation is resolving', async () => {
      expect(findButton().props('loading')).toBe(false);

      updateCheckbox(true);
      await nextTick();

      expect(findButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(findButton().props('loading')).toBe(false);
    });

    it('renders alert message when mutation has errors', async () => {
      mockMutation.mockResolvedValue(
        mockPermissionsMutationResponse({ errors: ['Something went wrong.'] }),
      );

      updateCheckbox(true);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Something went wrong.' });
      expect(mockToastShow).not.toHaveBeenCalled();
    });

    describe('when mutation is successful', () => {
      it('mutation is called with the correct variables', async () => {
        updateCheckbox(true);
        await waitForPromises();

        expect(mockMutation).toHaveBeenCalledWith({
          input: {
            fullPath,
            pushRepositoryForJobTokenAllowed: true,
          },
        });
      });

      it('renders toast message', async () => {
        updateCheckbox(true);
        await waitForPromises();

        expect(createAlert).not.toHaveBeenCalled();
        expect(mockToastShow).toHaveBeenCalledWith(
          `CI/CD job token permissions for 'ops' were successfully updated.`,
        );
      });
    });
  });
});
