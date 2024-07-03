import { GlAlert, GlCollapsibleListbox, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import InboundTokenAccess from '~/token_access/components/inbound_token_access.vue';
import GroupsAndProjectsListbox from '~/token_access/components/groups_and_projects_listbox.vue';
import inboundAddGroupOrProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_add_group_or_project_ci_job_token_scope.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '~/token_access/graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import getGroupsAndProjectsQuery from '~/token_access/graphql/queries/get_groups_and_projects.query.graphql';
import {
  inboundJobTokenScopeEnabledResponse,
  inboundJobTokenScopeDisabledResponse,
  inboundGroupsAndProjectsWithScopeResponse,
  inboundGroupsAndProjectsWithScopeResponseWithAddedItem,
  getGroupsAndProjectsResponse,
  inboundAddGroupOrProjectSuccessResponse,
  inboundRemoveGroupSuccess,
  inboundRemoveProjectSuccess,
  inboundUpdateScopeSuccessResponse,
} from './mock_data';

const projectPath = 'root/my-repo';
const testGroupPath = 'gitlab-org';
const testProjectPath = 'root/test';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/alert');

describe('TokenAccess component', () => {
  let wrapper;

  const inboundJobTokenScopeEnabledResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundJobTokenScopeEnabledResponse);
  const inboundJobTokenScopeDisabledResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundJobTokenScopeDisabledResponse);
  const inboundGroupsAndProjectsWithScopeResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundGroupsAndProjectsWithScopeResponse);
  const getGroupsAndProjectsSuccessResponseHandler = jest
    .fn()
    .mockResolvedValue(getGroupsAndProjectsResponse);
  const inboundAddGroupOrProjectSuccessResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundAddGroupOrProjectSuccessResponse);
  const inboundRemoveGroupSuccessHandler = jest.fn().mockResolvedValue(inboundRemoveGroupSuccess);
  const inboundRemoveProjectSuccessHandler = jest
    .fn()
    .mockResolvedValue(inboundRemoveProjectSuccess);
  const inboundUpdateScopeSuccessResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundUpdateScopeSuccessResponse);
  const failureHandler = jest.fn().mockRejectedValue(error);

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddProjectBtn = () => wrapper.findByTestId('add-project-btn');
  const findCancelBtn = () => wrapper.findByRole('button', { name: 'Cancel' });
  const findGroupOrProjectFormGroup = () => wrapper.findByTestId('group-or-project-form-group');
  const findGroupsAndProjectsListbox = () => wrapper.findComponent(GroupsAndProjectsListbox);
  const findListboxInput = () => wrapper.findComponent(GlCollapsibleListbox);
  const findRemoveProjectBtnAt = (i) =>
    wrapper.findAllByRole('button', { name: 'Remove access' }).at(i);
  const findToggleFormBtn = () => wrapper.findByTestId('toggle-form-btn');
  const findTokenDisabledAlert = () => wrapper.findComponent(GlAlert);

  const createMockApolloProvider = (requestHandlers) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (requestHandlers, mountFn = shallowMountExtended) => {
    wrapper = mountFn(InboundTokenAccess, {
      provide: {
        fullPath: projectPath,
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
    });
  };

  describe('loading state', () => {
    it('shows loading state while waiting on query to resolve', async () => {
      createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('fetching groups and projects and scope', () => {
    it('fetches groups and projects and scope correctly', () => {
      const expectedVariables = {
        fullPath: 'root/my-repo',
      };

      createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      expect(inboundJobTokenScopeEnabledResponseHandler).toHaveBeenCalledWith(expectedVariables);
      expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledWith(
        expectedVariables,
      );
    });

    it('handles fetch groups and projects error correctly', async () => {
      createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery, failureHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the projects',
      });
    });

    it('handles fetch scope error correctly', async () => {
      createComponent([
        [inboundGetCIJobTokenScopeQuery, failureHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
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
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(findTokenDisabledAlert().exists()).toBe(false);
    });

    it('the toggle is off and the alert is visible', async () => {
      createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
      expect(findTokenDisabledAlert().exists()).toBe(true);
    });

    describe('update ci job token scope', () => {
      it('calls inboundUpdateCIJobTokenScopeMutation mutation', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [inboundUpdateCIJobTokenScopeMutation, inboundUpdateScopeSuccessResponseHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        expect(findToggle().props('value')).toBe(true);

        findToggle().vm.$emit('change', false);

        await waitForPromises();

        expect(findToggle().props('value')).toBe(false);
        expect(inboundUpdateScopeSuccessResponseHandler).toHaveBeenCalledWith({
          input: {
            fullPath: 'root/my-repo',
            inboundJobTokenScopeEnabled: false,
          },
        });
      });

      it('handles update scope error correctly', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
            [inboundUpdateCIJobTokenScopeMutation, failureHandler],
          ],
          mountExtended,
        );

        await waitForPromises();

        expect(findToggle().props('value')).toBe(false);

        findToggle().vm.$emit('change', true);

        await waitForPromises();

        expect(findToggle().props('value')).toBe(false);
        expect(createAlert).toHaveBeenCalledWith({ message });
      });
    });
  });

  describe.each`
    type         | testPath
    ${'group'}   | ${testGroupPath}
    ${'project'} | ${testProjectPath}
  `('add $type', ({ type, testPath }) => {
    it(`calls add group or project mutation`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [getGroupsAndProjectsQuery, getGroupsAndProjectsSuccessResponseHandler],
          [
            inboundAddGroupOrProjectCIJobTokenScopeMutation,
            inboundAddGroupOrProjectSuccessResponseHandler,
          ],
        ],
        mountExtended,
      );

      await waitForPromises();

      await findToggleFormBtn().trigger('click');
      await findListboxInput().vm.$emit('select', testPath);
      findAddProjectBtn().trigger('click');

      expect(inboundAddGroupOrProjectSuccessResponseHandler).toHaveBeenCalledWith({
        projectPath,
        targetPath: testPath,
      });
    });

    it(`increments the ${type} count`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            jest
              .fn()
              .mockResolvedValueOnce(inboundGroupsAndProjectsWithScopeResponse)
              .mockResolvedValueOnce(inboundGroupsAndProjectsWithScopeResponseWithAddedItem),
          ],
          [getGroupsAndProjectsQuery, getGroupsAndProjectsSuccessResponseHandler],
          [
            inboundAddGroupOrProjectCIJobTokenScopeMutation,
            inboundAddGroupOrProjectSuccessResponseHandler,
          ],
        ],
        mountExtended,
      );

      await waitForPromises();

      expect(wrapper.findByTestId(`${type}-count`).text()).toBe('1');
      expect(wrapper.findByTestId(`${type}-count`).attributes('title')).toBe(
        `1 ${type} has access`,
      );

      await findToggleFormBtn().trigger('click');
      await findListboxInput().vm.$emit('select', testPath);
      findAddProjectBtn().trigger('click');

      await waitForPromises();

      expect(wrapper.findByTestId(`${type}-count`).text()).toBe('2');
      expect(wrapper.findByTestId(`${type}-count`).attributes('title')).toBe(
        `2 ${type}s have access`,
      );
    });

    it('add group or project handles error correctly', async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [getGroupsAndProjectsQuery, getGroupsAndProjectsSuccessResponseHandler],
          [inboundAddGroupOrProjectCIJobTokenScopeMutation, failureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      await findToggleFormBtn().trigger('click');
      await findListboxInput().vm.$emit('select', testPath);
      await findAddProjectBtn().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });

    it('clicking cancel hides the form and clears the target path', async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [getGroupsAndProjectsQuery, getGroupsAndProjectsSuccessResponseHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      await findToggleFormBtn().trigger('click');

      expect(findListboxInput().exists()).toBe(true);

      await findListboxInput().vm.$emit('select', testPath);
      await findCancelBtn().trigger('click');

      expect(findListboxInput().exists()).toBe(false);

      await findToggleFormBtn().trigger('click');

      expect(findListboxInput().props('selected')).toEqual('');
    });
  });

  describe.each`
    type         | testPath
    ${'group'}   | ${inboundGroupsAndProjectsWithScopeResponse.data.project.ciJobTokenScope.inboundAllowlist.nodes[0].fullPath}
    ${'project'} | ${inboundGroupsAndProjectsWithScopeResponse.data.project.ciJobTokenScope.groupsAllowlist.nodes[0].fullPath}
  `('add a duplicate $type', ({ testPath }) => {
    it(`validates whether path is already in the allowlist`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [getGroupsAndProjectsQuery, getGroupsAndProjectsSuccessResponseHandler],
          [
            inboundAddGroupOrProjectCIJobTokenScopeMutation,
            inboundAddGroupOrProjectSuccessResponseHandler,
          ],
        ],
        mountExtended,
      );

      await waitForPromises();

      await findToggleFormBtn().trigger('click');

      expect(findGroupOrProjectFormGroup().attributes('aria-invalid')).toBe(undefined);
      expect(findGroupsAndProjectsListbox().props('isValid')).toBe(true);

      await findListboxInput().vm.$emit('select', testPath);

      expect(findGroupOrProjectFormGroup().attributes('aria-invalid')).toBe('true');
      expect(findGroupsAndProjectsListbox().props('isValid')).toBe(false);
      expect(findAddProjectBtn().props('disabled')).toBe(true);
    });
  });

  describe.each`
    type         | index | mutation                                       | handler                               | target
    ${'group'}   | ${0}  | ${inboundRemoveGroupCIJobTokenScopeMutation}   | ${inboundRemoveGroupSuccessHandler}   | ${'targetGroupPath'}
    ${'project'} | ${1}  | ${inboundRemoveProjectCIJobTokenScopeMutation} | ${inboundRemoveProjectSuccessHandler} | ${'targetProjectPath'}
  `('remove $type', ({ type, index, mutation, handler, target }) => {
    it(`calls remove ${type} mutation`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [mutation, handler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtnAt(index).trigger('click');

      expect(handler).toHaveBeenCalledWith({
        projectPath,
        [target]: expect.any(String),
      });
    });

    it(`decrements the ${type} count`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            jest
              .fn()
              .mockResolvedValueOnce(inboundGroupsAndProjectsWithScopeResponseWithAddedItem)
              .mockResolvedValueOnce(inboundGroupsAndProjectsWithScopeResponse),
          ],
          [mutation, handler],
        ],
        mountExtended,
      );

      await waitForPromises();

      expect(wrapper.findByTestId(`${type}-count`).text()).toBe('2');
      expect(wrapper.findByTestId(`${type}-count`).attributes('title')).toBe(
        `2 ${type}s have access`,
      );

      findRemoveProjectBtnAt(index).trigger('click');

      await waitForPromises();

      expect(wrapper.findByTestId(`${type}-count`).text()).toBe('1');
      expect(wrapper.findByTestId(`${type}-count`).attributes('title')).toBe(
        `1 ${type} has access`,
      );
    });

    it(`remove ${type} handles error correctly`, async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [mutation, failureHandler],
        ],
        mountExtended,
      );

      await waitForPromises();

      findRemoveProjectBtnAt(index).trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });
});
