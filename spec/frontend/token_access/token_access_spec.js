import { GlToggle, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import TokenAccess from '~/token_access/components/token_access.vue';
import addProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/add_project_ci_job_token_scope.mutation.graphql';
import removeProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import {
  enabledJobTokenScope,
  disabledJobTokenScope,
  projectsWithScope,
  addProjectSuccess,
  removeProjectSuccess,
} from './mock_data';

const projectPath = 'root/my-repo';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/flash');

describe('TokenAccess component', () => {
  let wrapper;

  const enabledJobTokenScopeHandler = jest.fn().mockResolvedValue(enabledJobTokenScope);
  const disabledJobTokenScopeHandler = jest.fn().mockResolvedValue(disabledJobTokenScope);
  const getProjectsWithScope = jest.fn().mockResolvedValue(projectsWithScope);
  const addProjectSuccessHandler = jest.fn().mockResolvedValue(addProjectSuccess);
  const addProjectFailureHandler = jest.fn().mockRejectedValue(error);
  const removeProjectSuccessHandler = jest.fn().mockResolvedValue(removeProjectSuccess);
  const removeProjectFailureHandler = jest.fn().mockRejectedValue(error);

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddProjectBtn = () => wrapper.findByRole('button', { name: 'Add project' });
  const findRemoveProjectBtn = () => wrapper.findByRole('button', { name: 'Remove access' });
  const findTokenDisabledAlert = () => wrapper.findByTestId('token-disabled-alert');

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(TokenAccess, {
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it('shows loading state while waiting on query to resolve', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('toggle', () => {
    it('the toggle is on and the alert is hidden', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findTokenDisabledAlert().exists()).toBe(false);
    });

    it('the toggle is off and the alert is visible', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findTokenDisabledAlert().exists()).toBe(true);
    });
  });

  describe('add project', () => {
    it('calls add project mutation', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
          [addProjectCIJobTokenScopeMutation, addProjectSuccessHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findAddProjectBtn().trigger('click');

      expect(addProjectSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          targetProjectPath: 'root/test',
        },
      });
    });

    it('add project handles error correctly', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
          [addProjectCIJobTokenScopeMutation, addProjectFailureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findAddProjectBtn().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });

  describe('remove project', () => {
    it('calls remove project mutation', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
          [removeProjectCIJobTokenScopeMutation, removeProjectSuccessHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtn().trigger('click');

      expect(removeProjectSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectPath,
          targetProjectPath: 'root/332268-test',
        },
      });
    });

    it('remove project handles error correctly', async () => {
      createComponent(
        [
          [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
          [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
          [removeProjectCIJobTokenScopeMutation, removeProjectFailureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtn().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });
});
