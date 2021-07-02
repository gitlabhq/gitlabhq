import { GlToggle, GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import TokenAccess from '~/token_access/components/token_access.vue';
import addProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/add_project_ci_job_token_scope.mutation.graphql';
import removeProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/remove_project_ci_job_token_scope.mutation.graphql';
import updateCIJobTokenScopeMutation from '~/token_access/graphql/mutations/update_ci_job_token_scope.mutation.graphql';
import getCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_ci_job_token_scope.query.graphql';
import getProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/get_projects_with_ci_job_token_scope.query.graphql';
import {
  enabledJobTokenScope,
  disabledJobTokenScope,
  updateJobTokenScope,
  projectsWithScope,
  addProjectSuccess,
  removeProjectSuccess,
} from './mock_data';

const projectPath = 'root/my-repo';
const error = new Error('Error');
const localVue = createLocalVue();

localVue.use(VueApollo);

jest.mock('~/flash');

describe('TokenAccess component', () => {
  let wrapper;

  const enabledJobTokenScopeHandler = jest.fn().mockResolvedValue(enabledJobTokenScope);
  const disabledJobTokenScopeHandler = jest.fn().mockResolvedValue(disabledJobTokenScope);
  const updateJobTokenScopeHandler = jest.fn().mockResolvedValue(updateJobTokenScope);
  const getProjectsWithScope = jest.fn().mockResolvedValue(projectsWithScope);
  const addProjectSuccessHandler = jest.fn().mockResolvedValue(addProjectSuccess);
  const addProjectFailureHandler = jest.fn().mockRejectedValue(error);
  const removeProjectSuccessHandler = jest.fn().mockResolvedValue(removeProjectSuccess);
  const removeProjectFailureHandler = jest.fn().mockRejectedValue(error);

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddProjectBtn = () => wrapper.find('[data-testid="add-project-button"]');
  const findRemoveProjectBtn = () => wrapper.find('[data-testid="remove-project-button"]');
  const findTokenSection = () => wrapper.find('[data-testid="token-section"]');

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMount) => {
    wrapper = mountFn(TokenAccess, {
      localVue,
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
    it('the toggle should be enabled and the token section should show', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, enabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findTokenSection().exists()).toBe(true);
    });

    it('the toggle should be disabled and the token section should not show', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findTokenSection().exists()).toBe(false);
    });

    it('switching the toggle calls the mutation', async () => {
      createComponent([
        [getCIJobTokenScopeQuery, disabledJobTokenScopeHandler],
        [updateCIJobTokenScopeMutation, updateJobTokenScopeHandler],
        [getProjectsWithCIJobTokenScopeQuery, getProjectsWithScope],
      ]);

      await waitForPromises();

      findToggle().vm.$emit('change', true);

      expect(updateJobTokenScopeHandler).toHaveBeenCalledWith({
        input: { fullPath: projectPath, jobTokenScopeEnabled: true },
      });
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
        mount,
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
        mount,
      );

      await waitForPromises();

      findAddProjectBtn().trigger('click');

      await waitForPromises();

      expect(createFlash).toHaveBeenCalled();
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
        mount,
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
        mount,
      );

      await waitForPromises();

      findRemoveProjectBtn().trigger('click');

      await waitForPromises();

      expect(createFlash).toHaveBeenCalled();
    });
  });
});
