import { GlAlert, GlForm, GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewBranchForm from '~/jira_connect/branches/components/new_branch_form.vue';
import ProjectDropdown from '~/jira_connect/branches/components/project_dropdown.vue';
import SourceBranchDropdown from '~/jira_connect/branches/components/source_branch_dropdown.vue';
import {
  CREATE_BRANCH_ERROR_GENERIC,
  CREATE_BRANCH_ERROR_WITH_CONTEXT,
  CREATE_BRANCH_SUCCESS_ALERT,
} from '~/jira_connect/branches/constants';
import createBranchMutation from '~/jira_connect/branches/graphql/mutations/create_branch.mutation.graphql';

const mockProject = {
  id: 'test',
  fullPath: 'test-path',
  repository: {
    branchNames: ['main', 'f-test', 'release'],
    rootRef: 'main',
  },
};
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

const localVue = createLocalVue();

describe('NewBranchForm', () => {
  let wrapper;

  const findSourceBranchDropdown = () => wrapper.findComponent(SourceBranchDropdown);
  const findProjectDropdown = () => wrapper.findComponent(ProjectDropdown);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findButton = () => wrapper.findComponent(GlButton);

  const completeForm = async () => {
    await findInput().vm.$emit('input', 'cool-branch-name');
    await findProjectDropdown().vm.$emit('change', mockProject);
    await findSourceBranchDropdown().vm.$emit('change', 'source-branch');
  };

  function createMockApolloProvider({
    mockCreateBranchMutation = mockCreateBranchMutationSuccess,
  } = {}) {
    localVue.use(VueApollo);

    const mockApollo = createMockApollo([[createBranchMutation, mockCreateBranchMutation]]);

    return mockApollo;
  }

  function createComponent({ mockApollo } = {}) {
    wrapper = shallowMount(NewBranchForm, {
      localVue,
      apolloProvider: mockApollo || createMockApolloProvider(),
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when selecting items from dropdowns', () => {
    describe('when a project is selected', () => {
      it('sets the `selectedProject` prop for ProjectDropdown and SourceBranchDropdown', async () => {
        createComponent();

        const projectDropdown = findProjectDropdown();
        await projectDropdown.vm.$emit('change', mockProject);

        expect(projectDropdown.props('selectedProject')).toEqual(mockProject);
        expect(findSourceBranchDropdown().props('selectedProject')).toEqual(mockProject);
      });
    });

    describe('when a source branch is selected', () => {
      it('sets the `selectedBranchName` prop for SourceBranchDropdown', async () => {
        createComponent();

        const mockBranchName = 'main';
        const sourceBranchDropdown = findSourceBranchDropdown();
        await sourceBranchDropdown.vm.$emit('change', mockBranchName);

        expect(sourceBranchDropdown.props('selectedBranchName')).toBe(mockBranchName);
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

      it('displays a success message', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(CREATE_BRANCH_SUCCESS_ALERT.message);
        expect(alert.props()).toMatchObject({
          title: CREATE_BRANCH_SUCCESS_ALERT.title,
          variant: 'success',
        });
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
      `('', ({ mutation, alertTitle, alertText }) => {
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
          expect(alert.text()).toBe(alertText);
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
        await wrapper.findComponent(component).vm.$emit('error', { message: mockErrorMessage });
      });

      it('displays an alert', () => {
        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(mockErrorMessage);
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
