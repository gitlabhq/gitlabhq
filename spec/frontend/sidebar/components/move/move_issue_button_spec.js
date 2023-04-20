import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import ProjectSelect from '~/sidebar/components/move/issuable_move_dropdown.vue';
import MoveIssueButton from '~/sidebar/components/move/move_issue_button.vue';
import moveIssueMutation from '~/sidebar/queries/move_issue.mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

const projectFullPath = 'flight/FlightJS';
const projectsAutocompleteEndpoint = '/-/autocomplete/projects?project_id=1';
const issueIid = '15';

const mockDestinationProject = {
  full_path: 'gitlab-org/GitLabTest',
};

const mockWebUrl = `${mockDestinationProject.full_path}/issues/${issueIid}`;

const mockMutationErrorMessage = 'Example error message';

const resolvedMutationWithoutErrorsMock = jest.fn().mockResolvedValue({
  data: {
    issueMove: {
      issue: {
        id: issueIid,
        webUrl: mockWebUrl,
      },
      errors: [],
    },
  },
});

const resolvedMutationWithErrorsMock = jest.fn().mockResolvedValue({
  data: {
    issueMove: {
      errors: [{ message: mockMutationErrorMessage }],
    },
  },
});

const rejectedMutationMock = jest.fn().mockRejectedValue({});

describe('MoveIssueButton', () => {
  let wrapper;
  let fakeApollo;

  const findProjectSelect = () => wrapper.findComponent(ProjectSelect);
  const emitProjectSelectEvent = () => {
    findProjectSelect().vm.$emit('move-issuable', mockDestinationProject);
  };
  const createComponent = (mutationResolverMock = rejectedMutationMock) => {
    fakeApollo = createMockApollo([[moveIssueMutation, mutationResolverMock]]);

    wrapper = shallowMount(MoveIssueButton, {
      provide: {
        projectFullPath,
        projectsAutocompleteEndpoint,
        issueIid,
      },
      apolloProvider: fakeApollo,
    });
  };

  it('renders the project select dropdown', () => {
    createComponent();

    expect(findProjectSelect().props()).toMatchObject({
      projectsFetchPath: projectsAutocompleteEndpoint,
      dropdownButtonTitle: MoveIssueButton.i18n.title,
      dropdownHeaderTitle: MoveIssueButton.i18n.title,
      moveInProgress: false,
    });
  });

  describe('when the project is selected', () => {
    it('sets loading state and dropdown button text when issue is moving', async () => {
      createComponent();
      expect(findProjectSelect().props()).toMatchObject({
        dropdownButtonTitle: MoveIssueButton.i18n.title,
        moveInProgress: false,
      });

      emitProjectSelectEvent();
      await nextTick();

      expect(findProjectSelect().props()).toMatchObject({
        dropdownButtonTitle: MoveIssueButton.i18n.titleInProgress,
        moveInProgress: true,
      });
    });

    it.each`
      condition                      | mutation
      ${'a mutation returns errors'} | ${resolvedMutationWithErrorsMock}
      ${'a mutation is rejected'}    | ${rejectedMutationMock}
    `('sets loading state to false when $condition', async ({ mutation }) => {
      createComponent(mutation);
      emitProjectSelectEvent();

      await nextTick();
      expect(findProjectSelect().props('moveInProgress')).toBe(true);

      await waitForPromises();
      expect(findProjectSelect().props('moveInProgress')).toBe(false);
    });

    it('creates an alert and logs errors when a mutation returns errors', async () => {
      createComponent(resolvedMutationWithErrorsMock);
      emitProjectSelectEvent();

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: MoveIssueButton.i18n.moveErrorMessage,
        captureError: true,
        error: expect.any(Object),
      });
    });

    it('calls a mutation for the selected issue', async () => {
      createComponent(resolvedMutationWithoutErrorsMock);
      emitProjectSelectEvent();

      await waitForPromises();

      expect(resolvedMutationWithoutErrorsMock).toHaveBeenCalledWith({
        moveIssueInput: {
          projectPath: projectFullPath,
          iid: issueIid,
          targetProjectPath: mockDestinationProject.full_path,
        },
      });
    });

    it('redirects to the correct page when the mutation succeeds', async () => {
      createComponent(resolvedMutationWithoutErrorsMock);
      emitProjectSelectEvent();
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith(mockWebUrl);
    });
  });
});
