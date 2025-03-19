import {
  GlAlert,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormRadioGroup,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import InboundTokenAccess from '~/token_access/components/inbound_token_access.vue';
import {
  JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT,
  JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG,
} from '~/token_access/constants';
import AutopopulateAllowlistModal from '~/token_access/components/autopopulate_allowlist_modal.vue';
import NamespaceForm from '~/token_access/components/namespace_form.vue';
import RemoveAutopopulatedEntriesModal from '~/token_access/components/remove_autopopulated_entries_modal.vue';
import autopopulateAllowlistMutation from '~/token_access/graphql/mutations/autopopulate_allowlist.mutation.graphql';
import inboundRemoveGroupCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_remove_group_ci_job_token_scope.mutation.graphql';
import inboundRemoveProjectCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_remove_project_ci_job_token_scope.mutation.graphql';
import inboundUpdateCIJobTokenScopeMutation from '~/token_access/graphql/mutations/inbound_update_ci_job_token_scope.mutation.graphql';
import inboundGetCIJobTokenScopeQuery from '~/token_access/graphql/queries/inbound_get_ci_job_token_scope.query.graphql';
import inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery from '~/token_access/graphql/queries/inbound_get_groups_and_projects_with_ci_job_token_scope.query.graphql';
import getAuthLogCountQuery from '~/token_access/graphql/queries/get_auth_log_count.query.graphql';
import getCiJobTokenScopeAllowlistQuery from '~/token_access/graphql/queries/get_ci_job_token_scope_allowlist.query.graphql';
import removeAutopopulatedEntriesMutation from '~/token_access/graphql/mutations/remove_autopopulated_entries.mutation.graphql';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import TokenAccessTable from '~/token_access/components/token_access_table.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { stubComponent } from 'helpers/stub_component';
import {
  inboundJobTokenScopeEnabledResponse,
  inboundJobTokenScopeDisabledResponse,
  inboundGroupsAndProjectsWithScopeResponse,
  inboundRemoveNamespaceSuccess,
  inboundUpdateScopeSuccessResponse,
  mockAuthLogsCountResponse,
  mockAutopopulateAllowlistResponse,
  mockRemoveAutopopulatedEntriesResponse,
} from './mock_data';

const projectPath = 'root/my-repo';
const message = 'An error occurred';
const error = new Error(message);

Vue.use(VueApollo);

jest.mock('~/alert');

describe('TokenAccess component', () => {
  let wrapper;

  const authLogCountResponseHandler = jest.fn().mockResolvedValue(mockAuthLogsCountResponse(4));
  const authLogZeroCountResponseHandler = jest.fn().mockResolvedValue(mockAuthLogsCountResponse(0));
  const autopopulateAllowlistResponseHandler = jest
    .fn()
    .mockResolvedValue(mockAutopopulateAllowlistResponse());
  const autopopulateAllowlistResponseErrorHandler = jest
    .fn()
    .mockResolvedValue(mockAutopopulateAllowlistResponse({ errorMessage: message }));
  const inboundJobTokenScopeEnabledResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundJobTokenScopeEnabledResponse);
  const inboundJobTokenScopeDisabledResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundJobTokenScopeDisabledResponse);
  const inboundGroupsAndProjectsWithScopeResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundGroupsAndProjectsWithScopeResponse(true));
  const inboundGroupsAndProjectsWithoutAutopopulatedEntriesResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundGroupsAndProjectsWithScopeResponse(false));
  const inboundRemoveGroupSuccessHandler = jest
    .fn()
    .mockResolvedValue(inboundRemoveNamespaceSuccess);
  const inboundRemoveProjectSuccessHandler = jest
    .fn()
    .mockResolvedValue(inboundRemoveNamespaceSuccess);
  const inboundUpdateScopeSuccessResponseHandler = jest
    .fn()
    .mockResolvedValue(inboundUpdateScopeSuccessResponse);
  const removeAutopopulatedEntriesMutationHandler = jest
    .fn()
    .mockResolvedValue(mockRemoveAutopopulatedEntriesResponse());
  const removeAutopopulatedEntriesMutationErrorHandler = jest
    .fn()
    .mockResolvedValue(mockRemoveAutopopulatedEntriesResponse({ errorMessage: message }));
  const failureHandler = jest.fn().mockRejectedValue(error);
  const mockToastShow = jest.fn();

  const findAutopopulateAllowlistModal = () => wrapper.findComponent(AutopopulateAllowlistModal);
  const findAutopopulationAlert = () => wrapper.findByTestId('autopopulation-alert');
  const findAllowlistOptions = () => wrapper.findComponent(GlDisclosureDropdown);
  const findAllowlistOption = (index) =>
    wrapper.findAllComponents(GlDisclosureDropdownItem).at(index).find('button');
  const findFormSelector = () => wrapper.findByTestId('form-selector');
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findTokenDisabledAlert = () => wrapper.findComponent(GlAlert);
  const findNamespaceForm = () => wrapper.findComponent(NamespaceForm);
  const findSaveChangesBtn = () => wrapper.findByTestId('save-ci-job-token-scope-changes-btn');
  const findCountLoadingIcon = () => wrapper.findByTestId('count-loading-icon');
  const findGroupCount = () => wrapper.findByTestId('group-count');
  const findProjectCount = () => wrapper.findByTestId('project-count');
  const findConfirmActionModal = () => wrapper.findComponent(ConfirmActionModal);
  const findRemoveAutopopulatedEntriesModal = () =>
    wrapper.findComponent(RemoveAutopopulatedEntriesModal);
  const findTokenAccessTable = () => wrapper.findComponent(TokenAccessTable);

  const createComponent = (
    requestHandlers,
    {
      isJobTokenPoliciesEnabled = false,
      enforceAllowlist = false,
      projectAllowlistLimit = 2,
      stubs = {},
      isLoading = false,
    } = {},
  ) => {
    wrapper = shallowMountExtended(InboundTokenAccess, {
      provide: {
        fullPath: projectPath,
        enforceAllowlist,
        projectAllowlistLimit,
        isJobTokenPoliciesEnabled,
      },
      apolloProvider: createMockApollo(requestHandlers),
      mocks: {
        $toast: { show: mockToastShow },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        CrudComponent: stubComponent(CrudComponent),
        ...stubs,
      },
    });

    if (!isLoading) {
      return waitForPromises();
    }

    return Promise.resolve();
  };

  describe('loading state', () => {
    it('shows loading state while waiting on query to resolve', async () => {
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
        ],
        { isLoading: true },
      );

      await nextTick();

      expect(findTokenAccessTable().props('loading')).toBe(true);
      expect(findTokenAccessTable().props('loadingMessage')).toBe('');
    });
  });

  describe('setting allowlist limit', () => {
    // in the following tests, group count is 1, project count is 1, and auth log count is 4.
    describe('when fetching auth log count is successful', () => {
      const createComponentWithAllowlistLimit = async (projectAllowlistLimit) => {
        await createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithScopeResponseHandler,
            ],
            [getAuthLogCountQuery, authLogCountResponseHandler],
          ],
          { projectAllowlistLimit },
        );
      };

      it('calls the query with the expected variables', async () => {
        await createComponentWithAllowlistLimit(5);

        expect(authLogCountResponseHandler).toHaveBeenCalledWith({ fullPath: 'root/my-repo' });
      });

      it('passes the correct limit values to the autopopulation modal when allowlist limit is not exceeded', async () => {
        await createComponentWithAllowlistLimit(5);

        expect(findAutopopulateAllowlistModal().props('authLogExceedsLimit')).toBe(true);
        expect(findAutopopulateAllowlistModal().props('projectAllowlistLimit')).toBe(5);
      });

      it('passes the correct limit values to the autopopulation modal when allowlist limit is exceeded', async () => {
        await createComponentWithAllowlistLimit(10);

        expect(findAutopopulateAllowlistModal().props('authLogExceedsLimit')).toBe(false);
        expect(findAutopopulateAllowlistModal().props('projectAllowlistLimit')).toBe(10);
      });
    });

    it('handles fetches auth log count error correctly', async () => {
      await createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
        [getAuthLogCountQuery, failureHandler],
      ]);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching authorization logs count.',
      });
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
      await createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery, failureHandler],
      ]);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the projects',
      });
    });

    it('handles fetch scope error correctly', async () => {
      await createComponent([
        [inboundGetCIJobTokenScopeQuery, failureHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the job token scope value',
      });
    });
  });

  describe('inbound CI job token scope', () => {
    it('is on and the alert is hidden', async () => {
      await createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      expect(findRadioGroup().attributes('checked')).toBe('true');
      expect(findTokenDisabledAlert().exists()).toBe(false);
    });

    it('is off and the alert is visible', async () => {
      await createComponent([
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ]);

      expect(findRadioGroup().attributes('checked')).toBeUndefined();
      expect(findTokenDisabledAlert().exists()).toBe(true);
    });

    describe('radio group', () => {
      it('uses the correct "options" prop', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
        ]);

        const expectedOptions = [
          {
            value: false,
            text: 'All groups and projects',
          },
          {
            value: true,
            text: 'Only this project and any groups and projects in the allowlist',
          },
        ];

        expect(findRadioGroup().props('options')).toEqual(expectedOptions);
      });
    });

    describe('on update', () => {
      it('calls inboundUpdateCIJobTokenScopeMutation mutation', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [inboundUpdateCIJobTokenScopeMutation, inboundUpdateScopeSuccessResponseHandler],
        ]);

        const radioGroup = findRadioGroup();

        expect(radioGroup.attributes('checked')).toBe('true');

        await radioGroup.vm.$emit('input', false);

        expect(radioGroup.attributes('checked')).toBeUndefined();

        findSaveChangesBtn().vm.$emit('click');

        await waitForPromises();

        expect(inboundUpdateScopeSuccessResponseHandler).toHaveBeenCalledWith({
          input: {
            fullPath: 'root/my-repo',
            inboundJobTokenScopeEnabled: false,
          },
        });
      });

      it('when mutation is successful, renders toast message', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [inboundUpdateCIJobTokenScopeMutation, inboundUpdateScopeSuccessResponseHandler],
        ]);

        findSaveChangesBtn().vm.$emit('click');

        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(
          `CI/CD job token permissions for 'Test project' were successfully updated.`,
        );
      });

      it('handles an update error correctly', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
          [inboundUpdateCIJobTokenScopeMutation, failureHandler],
        ]);

        const radioGroup = findRadioGroup();

        expect(radioGroup.attributes('checked')).toBeUndefined();

        await radioGroup.vm.$emit('input', true);

        expect(radioGroup.attributes('checked')).toBe('true');

        findSaveChangesBtn().vm.$emit('click');

        await waitForPromises();

        expect(radioGroup.attributes('checked')).toBeUndefined();
        expect(createAlert).toHaveBeenCalledWith({ message });
      });
    });

    describe('save changes button', () => {
      it('shows a loading state on click', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [inboundUpdateCIJobTokenScopeMutation, inboundUpdateScopeSuccessResponseHandler],
        ]);

        const button = findSaveChangesBtn();

        expect(button.props('loading')).toBe(false);

        await button.vm.$emit('click');

        expect(button.props('loading')).toBe(true);

        await waitForPromises();

        expect(button.props('loading')).toBe(false);
      });

      it('has a correct title', async () => {
        await createComponent([
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [inboundUpdateCIJobTokenScopeMutation, inboundUpdateScopeSuccessResponseHandler],
        ]);

        expect(findSaveChangesBtn().text()).toBe('Save Changes');
      });
    });
  });

  describe('namespace form', () => {
    beforeEach(() =>
      createComponent(
        [
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
        ],
        { stubs: { CrudComponent } },
      ),
    );

    it('does not show form on page load', () => {
      expect(findNamespaceForm().exists()).toBe(false);
    });

    describe('when Add group or project button is clicked', () => {
      it('renders the namespace form when clicking "Add group or project option"', async () => {
        expect(findNamespaceForm().exists()).toBe(false);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT);
        await nextTick();

        expect(findNamespaceForm().exists()).toBe(true);
      });

      it('closes form when form emits close event', async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT);
        await nextTick();

        findNamespaceForm().vm.$emit('close');
        await nextTick();

        expect(findNamespaceForm().exists()).toBe(false);
      });

      it('refetches groups and projects when form emits saved event', async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT);
        await nextTick();

        findNamespaceForm().vm.$emit('saved');

        expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('when importing entries from authorization log', () => {
    beforeEach(() =>
      createComponent(
        [
          [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
          [
            inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
            inboundGroupsAndProjectsWithScopeResponseHandler,
          ],
          [autopopulateAllowlistMutation, autopopulateAllowlistResponseHandler],
          [removeAutopopulatedEntriesMutation, removeAutopopulatedEntriesMutationHandler],
          [getAuthLogCountQuery, authLogCountResponseHandler],
        ],
        {
          stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
        },
      ),
    );

    describe('autopopulate entries', () => {
      it('renders the autopopulate allowlist modal when clicking "All projects in authentication log"', async () => {
        expect(findAutopopulateAllowlistModal().props('showModal')).toBe(false);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        await nextTick();

        expect(findAutopopulateAllowlistModal().props('showModal')).toBe(true);
      });

      it('unselects dropdown option when autopopulate allowlist modal is hidden', async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('hide');
        await nextTick();

        expect(findFormSelector().props('selected')).toBe(null);
      });

      it('shows loading state while autopopulating entries', async () => {
        expect(findCountLoadingIcon().exists()).toBe(false);
        expect(findTokenAccessTable().props('loading')).toBe(false);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('autopopulate-allowlist');

        await nextTick();

        expect(findCountLoadingIcon().exists()).toBe(true);
        expect(findTokenAccessTable().props('loading')).toBe(true);
        expect(findTokenAccessTable().props('loadingMessage')).toBe(
          'Auto-populating allowlist entries. Please wait while the action completes.',
        );
      });

      it('resets loading state after autopopulating entries', async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('autopopulate-allowlist');

        await nextTick();

        expect(findTokenAccessTable().props('loadingMessage')).toBe(
          'Auto-populating allowlist entries. Please wait while the action completes.',
        );

        await waitForPromises();

        expect(findCountLoadingIcon().exists()).toBe(false);
        expect(findTokenAccessTable().props('loading')).toBe(false);
        expect(findTokenAccessTable().props('loadingMessage')).toBe('');
      });

      it('calls the autopopulate allowlist mutation and refetches allowlist and job token setting', async () => {
        expect(autopopulateAllowlistResponseHandler).toHaveBeenCalledTimes(0);
        expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledTimes(1);
        expect(inboundJobTokenScopeEnabledResponseHandler).toHaveBeenCalledTimes(1);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('autopopulate-allowlist');
        await waitForPromises();
        await nextTick();

        expect(autopopulateAllowlistResponseHandler).toHaveBeenCalledTimes(1);
        expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledTimes(2);
        expect(inboundJobTokenScopeEnabledResponseHandler).toHaveBeenCalledTimes(2);
      });

      it('shows error alert when mutation returns an error', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithScopeResponseHandler,
            ],
            [autopopulateAllowlistMutation, autopopulateAllowlistResponseErrorHandler],
            [getAuthLogCountQuery, authLogCountResponseHandler],
          ],
          {
            stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
          },
        );

        await waitForPromises();

        expect(findAutopopulationAlert().exists()).toBe(false);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('autopopulate-allowlist');
        await waitForPromises();
        await nextTick();

        expect(findAutopopulationAlert().text()).toBe('An error occurred');
      });

      it('shows error alert when mutation fails', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithScopeResponseHandler,
            ],
            [autopopulateAllowlistMutation, failureHandler],
            [getAuthLogCountQuery, authLogCountResponseHandler],
          ],
          {
            stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
          },
        );

        await waitForPromises();

        expect(findAutopopulationAlert().exists()).toBe(false);

        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_AUTOPOPULATE_AUTH_LOG);
        findAutopopulateAllowlistModal().vm.$emit('autopopulate-allowlist');
        await waitForPromises();
        await nextTick();

        expect(findAutopopulationAlert().text()).toBe(
          'An error occurred while adding the authentication log entries. Please try again.',
        );
      });
    });

    describe('remove autopopulated entries', () => {
      const triggerRemoveEntries = () => {
        findAllowlistOption(0).trigger('click');
        findRemoveAutopopulatedEntriesModal().vm.$emit('remove-entries');
      };

      it('additional actions are available in the disclosure dropdown', () => {
        expect(findAllowlistOptions().exists()).toBe(true);
      });

      it('"Remove only entries auto-added" renders the remove autopopulated entries modal', async () => {
        expect(findRemoveAutopopulatedEntriesModal().props('showModal')).toBe(false);

        findAllowlistOption(0).trigger('click');
        await nextTick();

        expect(findRemoveAutopopulatedEntriesModal().props('showModal')).toBe(true);
      });

      it('shows loading state while remove autopopulated entries mutation is processing', async () => {
        expect(findCountLoadingIcon().exists()).toBe(false);
        expect(findTokenAccessTable().props('loading')).toBe(false);

        triggerRemoveEntries();

        await nextTick();

        expect(findCountLoadingIcon().exists()).toBe(true);
        expect(findTokenAccessTable().props('loading')).toBe(true);
        expect(findTokenAccessTable().props('loadingMessage')).toBe(
          'Removing auto-added allowlist entries. Please wait while the action completes.',
        );
      });

      it('resets loading state after removing autopopulated entries', async () => {
        triggerRemoveEntries();
        await nextTick();

        expect(findTokenAccessTable().props('loadingMessage')).toBe(
          'Removing auto-added allowlist entries. Please wait while the action completes.',
        );

        await waitForPromises();

        expect(findCountLoadingIcon().exists()).toBe(false);
        expect(findTokenAccessTable().props('loading')).toBe(false);
        expect(findTokenAccessTable().props('loadingMessage')).toBe('');
      });

      it('calls the remove autopopulated entries mutation and refetches allowlist', async () => {
        expect(removeAutopopulatedEntriesMutationHandler).toHaveBeenCalledTimes(0);
        expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledTimes(1);

        triggerRemoveEntries();
        await waitForPromises();
        await nextTick();

        expect(removeAutopopulatedEntriesMutationHandler).toHaveBeenCalledTimes(1);
        expect(inboundGroupsAndProjectsWithScopeResponseHandler).toHaveBeenCalledTimes(2);
      });

      it('shows toast message when mutation is successful', async () => {
        triggerRemoveEntries();
        await waitForPromises();
        await nextTick();

        expect(mockToastShow).toHaveBeenCalledWith(
          'Authentication log entries were successfully removed from the allowlist.',
        );
      });

      it('shows error alert when mutation returns an error', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithScopeResponseHandler,
            ],
            [removeAutopopulatedEntriesMutation, removeAutopopulatedEntriesMutationErrorHandler],
            [getAuthLogCountQuery, authLogCountResponseHandler],
          ],
          {
            stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
          },
        );

        await waitForPromises();

        expect(findAutopopulationAlert().exists()).toBe(false);

        triggerRemoveEntries();
        await waitForPromises();
        await nextTick();

        expect(findAutopopulationAlert().text()).toBe('An error occurred');
      });

      it('shows error alert when mutation fails', async () => {
        createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithScopeResponseHandler,
            ],
            [removeAutopopulatedEntriesMutation, failureHandler],
            [getAuthLogCountQuery, authLogCountResponseHandler],
          ],
          {
            stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
          },
        );

        await waitForPromises();

        expect(findAutopopulationAlert().exists()).toBe(false);

        triggerRemoveEntries();
        await waitForPromises();
        await nextTick();

        expect(findAutopopulationAlert().text()).toBe(
          'An error occurred while removing the auto-added log entries. Please try again.',
        );
      });

      it('modal can be re-opened again after it closes', async () => {
        findAllowlistOption(0).trigger('click');
        await nextTick();

        expect(findRemoveAutopopulatedEntriesModal().props('showModal')).toBe(true);

        findRemoveAutopopulatedEntriesModal().vm.$emit('hide');
        await nextTick();

        expect(findRemoveAutopopulatedEntriesModal().props('showModal')).toBe(false);

        findAllowlistOption(0).trigger('click');
        await nextTick();

        expect(findRemoveAutopopulatedEntriesModal().props('showModal')).toBe(true);
      });
    });

    describe('allowlist actions', () => {
      beforeEach(async () => {
        await createComponent(
          [
            [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeEnabledResponseHandler],
            [
              inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
              inboundGroupsAndProjectsWithoutAutopopulatedEntriesResponseHandler,
            ],
            [getAuthLogCountQuery, authLogZeroCountResponseHandler],
          ],
          {
            stubs: { CrudComponent, GlDisclosureDropdown, GlDisclosureDropdownItem },
          },
        );
        await nextTick();
      });

      it('hides add auth log entries option if auth log count is zero', () => {
        expect(findFormSelector().props('items')).toMatchObject([
          {
            text: 'Group or project',
            value: 'JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT',
          },
        ]);
      });

      it('hides remove auth log entries option if there are no autopopulated entries', () => {
        expect(findAllowlistOptions().exists()).toBe(false);
      });
    });
  });

  describe.each`
    type                           | mutation                                       | handler
    ${'CiJobTokenAccessibleGroup'} | ${inboundRemoveGroupCIJobTokenScopeMutation}   | ${inboundRemoveGroupSuccessHandler}
    ${'Project'}                   | ${inboundRemoveProjectCIJobTokenScopeMutation} | ${inboundRemoveProjectSuccessHandler}
  `('remove $type', ({ type, mutation, handler }) => {
    describe('when remove button is clicked', () => {
      beforeEach(async () => {
        await createComponent([[mutation, handler]]);

        findTokenAccessTable().vm.$emit('removeItem', { fullPath: 'full/path' });
      });

      it('shows remove confirmation modal', () => {
        expect(findConfirmActionModal().props()).toMatchObject({
          title: `Remove full/path`,
          actionFn: wrapper.vm.removeItem,
          actionText: 'Remove group or project',
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
        await createComponent([[mutation, failureHandler]]);

        findTokenAccessTable().vm.$emit('removeItem', { fullPath: 'full/path', __typename: type });
      });

      it('returns an error', async () => {
        await expect(wrapper.vm.removeItem()).rejects.toThrow(error);
      });
    });
  });

  describe('when allowlist is enforced by admin', () => {
    beforeEach(() => {
      const requestHandlers = [
        [inboundGetCIJobTokenScopeQuery, inboundJobTokenScopeDisabledResponseHandler],
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ];

      return createComponent(requestHandlers, { enforceAllowlist: true });
    });

    it('hides alert, options, and submit button', () => {
      expect(findTokenDisabledAlert().exists()).toBe(false);
      expect(findRadioGroup().exists()).toBe(false);
      expect(findSaveChangesBtn().exists()).toBe(false);
    });
  });

  describe('allowlist counts', () => {
    beforeEach(() => {
      const requestHandlers = [
        [
          inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery,
          inboundGroupsAndProjectsWithScopeResponseHandler,
        ],
      ];

      return createComponent(requestHandlers, { stubs: { CrudComponent } });
    });

    describe('when allowlist query is loaded', () => {
      it('does not show loading icon', () => {
        expect(findCountLoadingIcon().exists()).toBe(false);
      });

      it('shows group count', () => {
        expect(findGroupCount().text()).toBe('1');
      });

      it('has group count tooltip', () => {
        const tooltip = getBinding(findGroupCount().element, 'gl-tooltip');

        expect(tooltip).toMatchObject({ modifiers: { d0: true }, value: '1 group has access' });
      });

      it('shows project count', () => {
        expect(findProjectCount().text()).toBe('1');
      });

      it('has project count tooltip', () => {
        const tooltip = getBinding(findProjectCount().element, 'gl-tooltip');

        expect(tooltip).toMatchObject({ modifiers: { d0: true }, value: '1 project has access' });
      });
    });

    describe('when allowlist query is loading', () => {
      beforeEach(async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT);
        await nextTick();

        findNamespaceForm().vm.$emit('saved');
      });

      it('shows loading icon', () => {
        expect(findCountLoadingIcon().exists()).toBe(true);
      });

      it('does not show group count', () => {
        expect(findGroupCount().exists()).toBe(false);
      });

      it('does not show project count', () => {
        expect(findProjectCount().exists()).toBe(false);
      });
    });
  });

  describe.each`
    isJobTokenPoliciesEnabled | oldQueryCallCount | newQueryCallCount
    ${true}                   | ${0}              | ${1}
    ${false}                  | ${1}              | ${0}
  `(
    'when isJobTokenPoliciesEnabled is $isJobTokenPoliciesEnabled',
    ({ isJobTokenPoliciesEnabled, oldQueryCallCount, newQueryCallCount }) => {
      const oldQueryHandler = jest.fn();
      const newQueryHandler = jest.fn();

      beforeEach(() => {
        createComponent(
          [
            [inboundGetGroupsAndProjectsWithCIJobTokenScopeQuery, oldQueryHandler],
            [getCiJobTokenScopeAllowlistQuery, newQueryHandler],
          ],
          { isJobTokenPoliciesEnabled },
        );
      });

      it(`calls the old query ${oldQueryCallCount} times`, () => {
        expect(oldQueryHandler).toHaveBeenCalledTimes(oldQueryCallCount);
      });

      it(`calls the new query ${newQueryCallCount} times`, () => {
        expect(newQueryHandler).toHaveBeenCalledTimes(newQueryCallCount);
      });
    },
  );

  describe('editing an allowlist item', () => {
    const item = {};

    beforeEach(async () => {
      await createComponent([], { stubs: { CrudComponent } });
      findTokenAccessTable().vm.$emit('editItem', item);
    });

    it('shows the form with the namespace', () => {
      expect(findNamespaceForm().props('namespace')).toBe(item);
    });

    describe('when form is closed', () => {
      beforeEach(() => findNamespaceForm().vm.$emit('close'));

      it('clears the selected namespace', async () => {
        findFormSelector().vm.$emit('select', JOB_TOKEN_FORM_ADD_GROUP_OR_PROJECT);
        await nextTick();

        expect(findNamespaceForm().props('namespace')).toBe(null);
      });
    });
  });
});
