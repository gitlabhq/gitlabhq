import { GlToggle, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import OutboundTokenAccess from '~/token_access/components/outbound_token_access.vue';
import removeProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import updateCIJobTokenScopeMutation from '~/token_access/graphql/mutations/update_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import {
  enabledJobTokenScope,
  disabledJobTokenScope,
  projectsWithScope,
  removeProjectSuccess,
  updateScopeSuccess,
} from './mock_data';

const projectPath = 'root/my-repo';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/alert');

describe('TokenAccess component', () => {
  let wrapper;

  const enabledJobTokenScopeHandler = jest.fn().mockResolvedValue(enabledJobTokenScope);
  const disabledJobTokenScopeHandler = jest.fn().mockResolvedValue(disabledJobTokenScope);
  const getProjectsWithScopeHandler = jest.fn().mockResolvedValue(projectsWithScope);
  const removeProjectSuccessHandler = jest.fn().mockResolvedValue(removeProjectSuccess);
  const updateScopeSuccessHandler = jest.fn().mockResolvedValue(updateScopeSuccess);
  const failureHandler = jest.fn().mockRejectedValue(error);

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddProjectBtn = () => wrapper.findByRole('button', { name: 'Add project' });
  const findRemoveProjectBtn = () => wrapper.findByRole('button', { name: 'Remove access' });
  const findDeprecationAlert = () => wrapper.findByTestId('deprecation-alert');
  const findConfirmActionModal = () => wrapper.findComponent(ConfirmActionModal);

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(OutboundTokenAccess, {
      provide: {
        fullPath: projectPath,
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
      data() {
        return {
          targetProjectPath: 'root/test',
        };
      },
    });
  };

  describe('loading state', () => {
    it('shows loading state while waiting on query to resolve', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('fetching projects and scope', () => {
    it('fetches projects and scope correctly', () => {
      const expectedVariables = {
        fullPath: 'root/my-repo',
      };

      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      expect(enabledJobTokenScopeHandler).toHaveBeenCalledWith(expectedVariables);
      expect(getProjectsWithScopeHandler).toHaveBeenCalledWith(expectedVariables);
    });

    it('handles fetch projects error correctly', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, failureHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the projects',
      });
    });

    it('handles fetch scope error correctly', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, failureHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the job token scope value',
      });
    });
  });

  describe('toggle', () => {
    it('the toggle is on and the alert is hidden', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
    });

    describe('update ci job token scope', () => {
      it('calls updateCIJobTokenScopeMutation mutation', async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
            [updateCIJobTokenScopeMutation, updateScopeSuccessHandler],
          ],
          mountExtended,
        );

        await waitForPromises();
        findToggle().vm.$emit('change', false);
        findToggle().vm.$emit('change');

        expect(updateScopeSuccessHandler).toHaveBeenCalledWith({
          input: {
            fullPath: 'root/my-repo',
            jobTokenScopeEnabled: false,
          },
        });
      });

      it('handles update scope error correctly', async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
            [updateCIJobTokenScopeMutation, failureHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        findToggle().vm.$emit('change', true);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({ message });
      });
    });

    it('the toggle is off and the deprecation alert is visible', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
        ],
        shallowMountExtended,
        true,
      );

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findToggle().props('disabled')).toBe(true);
      expect(findDeprecationAlert().exists()).toBe(true);
    });

    it('contains a warning message about disabling the current configuration', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
        ],
        mountExtended,
        true,
      );

      await waitForPromises();

      expect(findToggle().text()).toContain('Disabling this feature is a permanent change.');
    });
  });

  describe('remove project', () => {
    describe('when remove button is clicked', () => {
      beforeEach(async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
            [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
            [removeProjectCIJobTokenScopeMutation, removeProjectSuccessHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        return findRemoveProjectBtn().trigger('click');
      });

      it('shows remove confirmation modal', () => {
        expect(findConfirmActionModal().props()).toMatchObject({
          title: 'Remove root/332268-test',
          actionFn: wrapper.vm.removeProject,
          actionText: 'Remove group or project',
        });
      });

      describe('when confirmation modal calls the action', () => {
        beforeEach(() => findConfirmActionModal().vm.performAction());

        it(`calls remove mutation`, () => {
          expect(removeProjectSuccessHandler).toHaveBeenCalledWith({
            input: {
              projectPath,
              targetProjectPath: 'root/332268-test',
            },
          });
        });
      });

      describe('after confirmation modal closes', () => {
        beforeEach(() => findConfirmActionModal().vm.$emit('close'));

        it('hides remove confirmation modal', () => {
          expect(findConfirmActionModal().exists()).toBe(false);
        });
      });
    });

    describe('when there is a mutation error', () => {
      beforeEach(async () => {
        createComponent(
          [
            [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
            [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
            [removeProjectCIJobTokenScopeMutation, failureHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        return findRemoveProjectBtn().trigger('click');
      });

      it('returns an error', async () => {
        await expect(wrapper.vm.removeProject()).rejects.toThrow(error);
      });
    });
  });

  describe('adding a new project', () => {
    it('disables the button for adding new projects', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScopeHandler],
        ],
        mountExtended,
        true,
        false,
      );

      await waitForPromises();

      expect(findAddProjectBtn().attributes('disabled')).toBe('disabled');
    });
  });
});
