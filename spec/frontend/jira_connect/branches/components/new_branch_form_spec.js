import { GlAlert, GlForm, GlFormInput, GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewBranchForm from '~/jira_connect/branches/components/new_branch_form.vue';
import ProjectDropdown from '~/jira_connect/branches/components/project_dropdown.vue';
import SourceBranchDropdown from '~/jira_connect/branches/components/source_branch_dropdown.vue';
import {
  CREATE_BRANCH_ERROR_GENERIC,
  CREATE_BRANCH_ERROR_WITH_CONTEXT,
  I18N_NEW_BRANCH_PERMISSION_ALERT,
} from '~/jira_connect/branches/constants';
import createBranchMutation from '~/jira_connect/branches/graphql/mutations/create_branch.mutation.graphql';
import { mockProjects } from '../mock_data';

const mockProject = mockProjects[0];
const mockCreateBranchMutationResponse = {
  data: {
    createBranch: {
      clientMutationId: 1,
      errors: [],
    },
  },
};
const mockCreateBranchMutationResponseWithErrors = {
  data: {
    createBranch: {
      clientMutationId: 1,
      errors: ['everything is broken, sorry.'],
    },
  },
};
const mockCreateBranchMutationSuccess = jest
  .fn()
  .mockResolvedValue(mockCreateBranchMutationResponse);
const mockCreateBranchMutationWithErrors = jest
  .fn()
  .mockResolvedValue(mockCreateBranchMutationResponseWithErrors);
const mockCreateBranchMutationFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));
const mockMutationLoading = jest.fn().mockReturnValue(new Promise(() => {}));

describe('NewBranchForm', () => {
  let wrapper;

  const findSourceBranchDropdown = () => wrapper.findComponent(SourceBranchDropdown);
  const findProjectDropdown = () => wrapper.findComponent(ProjectDropdown);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAlertSprintf = () => findAlert().findComponent(GlSprintf);
  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findButton = () => wrapper.findComponent(GlButton);

  const completeForm = async () => {
    await findProjectDropdown().vm.$emit('change', mockProject);
    await findSourceBranchDropdown().vm.$emit('change', 'source-branch');
    await findInput().vm.$emit('input', 'cool-branch-name');
  };

  function createMockApolloProvider({
    mockCreateBranchMutation = mockCreateBranchMutationSuccess,
  } = {}) {
    Vue.use(VueApollo);

    const mockApollo = createMockApollo([[createBranchMutation, mockCreateBranchMutation]]);

    return mockApollo;
  }

  function createComponent({ mockApollo, provide } = {}) {
    wrapper = shallowMount(NewBranchForm, {
      apolloProvider: mockApollo || createMockApolloProvider(),
      provide: {
        initialBranchName: '',
        ...provide,
      },
    });
  }

  describe('when selecting items from dropdowns', () => {
    describe('when no project selected', () => {
      beforeEach(() => {
        createComponent();
      });

      it('hides source branch selection and branch name input', () => {
        expect(findSourceBranchDropdown().exists()).toBe(false);
        expect(findInput().exists()).toBe(false);
      });

      it('disables the submit button', () => {
        expect(findButton().props('disabled')).toBe(true);
      });
    });

    describe('when a valid project is selected', () => {
      describe("when a source branch isn't selected", () => {
        beforeEach(async () => {
          createComponent();
          await findProjectDropdown().vm.$emit('change', mockProject);
        });

        it('sets the `selectedProject` prop for ProjectDropdown and SourceBranchDropdown', () => {
          expect(findProjectDropdown().props('selectedProject')).toEqual(mockProject);
          expect(findSourceBranchDropdown().exists()).toBe(true);
          expect(findSourceBranchDropdown().props('selectedProject')).toEqual(mockProject);
        });

        it('disables the submit button', () => {
          expect(findButton().props('disabled')).toBe(true);
        });

        it('renders branch input field', () => {
          expect(findInput().exists()).toBe(true);
        });
      });

      describe('when `initialBranchName` is provided', () => {
        it('sets value of branch name input to `initialBranchName` by default', async () => {
          const mockInitialBranchName = 'ap1-test-branch-name';

          createComponent({ provide: { initialBranchName: mockInitialBranchName } });
          await findProjectDropdown().vm.$emit('change', mockProject);

          expect(findInput().attributes('value')).toBe(mockInitialBranchName);
        });
      });

      describe('when a source branch is selected', () => {
        it('sets the `selectedBranchName` prop for SourceBranchDropdown', async () => {
          createComponent();
          await completeForm();

          const mockBranchName = 'main';
          const sourceBranchDropdown = findSourceBranchDropdown();
          await sourceBranchDropdown.vm.$emit('change', mockBranchName);

          expect(sourceBranchDropdown.props('selectedBranchName')).toBe(mockBranchName);
        });

        describe.each`
          branchName       | submitButtonDisabled
          ${undefined}     | ${true}
          ${''}            | ${true}
          ${' '}           | ${true}
          ${'test-branch'} | ${false}
        `('when branch name is $branchName', ({ branchName, submitButtonDisabled }) => {
          it(`sets submit button 'disabled' prop to ${submitButtonDisabled}`, async () => {
            createComponent();
            await completeForm();
            await findInput().vm.$emit('input', branchName);

            expect(findButton().props('disabled')).toBe(submitButtonDisabled);
          });
        });
      });
    });

    describe("when user doesn't have push permissions for the selected project", () => {
      beforeEach(async () => {
        createComponent();

        const projectDropdown = findProjectDropdown();
        await projectDropdown.vm.$emit('change', {
          ...mockProject,
          userPermissions: { pushCode: false },
        });
      });

      it('displays an alert', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(findAlertSprintf().attributes('message')).toBe(I18N_NEW_BRANCH_PERMISSION_ALERT);
        expect(alert.props('variant')).toBe('warning');
        expect(alert.props('dismissible')).toBe(false);
      });

      it('hides source branch selection and branch name input', () => {
        expect(findSourceBranchDropdown().exists()).toBe(false);
        expect(findInput().exists()).toBe(false);
      });
    });
  });

  describe('when submitting form', () => {
    describe('when form submission is loading', () => {
      it('sets submit button `loading` prop to `true`', async () => {
        createComponent({
          mockApollo: createMockApolloProvider({
            mockCreateBranchMutation: mockMutationLoading,
          }),
        });

        await completeForm();

        await findForm().vm.$emit('submit', new Event('submit'));
        await waitForPromises();

        expect(findButton().props('loading')).toBe(true);
      });
    });

    describe('when form submission is successful', () => {
      beforeEach(async () => {
        createComponent();

        await completeForm();

        await findForm().vm.$emit('submit', new Event('submit'));
        await waitForPromises();
      });

      it('emits `success` event', () => {
        expect(wrapper.emitted('success')).toHaveLength(1);
      });

      it('called `createBranch` mutation correctly', () => {
        expect(mockCreateBranchMutationSuccess).toHaveBeenCalledWith({
          name: 'cool-branch-name',
          projectPath: mockProject.fullPath,
          ref: 'source-branch',
        });
      });

      it('sets submit button `loading` prop to `false`', () => {
        expect(findButton().props('loading')).toBe(false);
      });
    });

    describe('when form submission fails', () => {
      describe.each`
        scenario                 | mutation                              | alertTitle                          | alertText
        ${'with errors-as-data'} | ${mockCreateBranchMutationWithErrors} | ${CREATE_BRANCH_ERROR_WITH_CONTEXT} | ${mockCreateBranchMutationResponseWithErrors.data.createBranch.errors[0]}
        ${'top-level error'}     | ${mockCreateBranchMutationFailed}     | ${''}                               | ${CREATE_BRANCH_ERROR_GENERIC}
      `('given $scenario', ({ mutation, alertTitle, alertText }) => {
        beforeEach(async () => {
          createComponent({
            mockApollo: createMockApolloProvider({
              mockCreateBranchMutation: mutation,
            }),
          });

          await completeForm();

          await findForm().vm.$emit('submit', new Event('submit'));
          await waitForPromises();
        });

        it('displays an alert', () => {
          const alert = findAlert();
          expect(alert.exists()).toBe(true);
          expect(findAlertSprintf().attributes('message')).toBe(alertText);
          expect(alert.props()).toMatchObject({ title: alertTitle, variant: 'danger' });
        });

        it('sets submit button `loading` prop to `false`', () => {
          expect(findButton().props('loading')).toBe(false);
        });
      });
    });
  });

  describe('error handling', () => {
    describe.each`
      component               | componentName
      ${SourceBranchDropdown} | ${'SourceBranchDropdown'}
      ${ProjectDropdown}      | ${'ProjectDropdown'}
    `('when $componentName emits error', ({ component }) => {
      const mockErrorMessage = 'oh noes!';

      beforeEach(async () => {
        createComponent();
        await completeForm();
        await wrapper.findComponent(component).vm.$emit('error', { message: mockErrorMessage });
      });

      it('displays an alert', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(findAlertSprintf().attributes('message')).toBe(mockErrorMessage);
        expect(alert.props('variant')).toBe('danger');
      });

      describe('when alert is dismissed', () => {
        it('hides alert', async () => {
          const alert = findAlert();
          expect(alert.exists()).toBe(true);

          await alert.vm.$emit('dismiss');

          expect(alert.exists()).toBe(false);
        });
      });
    });
  });
});
