import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { createAlert } from '~/alert';
import { logError } from '~/lib/logger';
import IssuableMoveDropdown from '~/sidebar/components/move/issuable_move_dropdown.vue';
import issuableEventHub from '~/issues/list/eventhub';
import MoveIssuesButton from '~/sidebar/components/move/move_issues_button.vue';
import moveIssueMutation from '~/sidebar/queries/move_issue.mutation.graphql';
import getIssuesQuery from 'ee_else_ce/issues/list/queries/get_issues.query.graphql';
import getIssuesCountsQuery from 'ee_else_ce/issues/list/queries/get_issues_counts.query.graphql';
import { getIssuesCountsQueryResponse, getIssuesQueryResponse } from 'jest/issues/list/mock_data';
import {
  WORK_ITEM_TYPE_ENUM_ISSUE,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
  WORK_ITEM_TYPE_ENUM_TASK,
  WORK_ITEM_TYPE_ENUM_TEST_CASE,
} from '~/work_items/constants';

jest.mock('~/alert');
jest.mock('~/lib/logger');
useMockLocationHelper();

const mockDefaultProps = {
  projectFullPath: 'flight/FlightJS',
  projectsFetchPath: '/-/autocomplete/projects?project_id=1',
};

const mockDestinationProject = {
  full_path: 'gitlab-org/GitLabTest',
};

const mockMutationErrorMessage = 'Example error message';

const mockIssue = {
  iid: '15',
  type: WORK_ITEM_TYPE_ENUM_ISSUE,
};

const mockIncident = {
  iid: '32',
  type: WORK_ITEM_TYPE_ENUM_INCIDENT,
};

const mockTask = {
  iid: '40',
  type: WORK_ITEM_TYPE_ENUM_TASK,
};

const mockTestCase = {
  iid: '51',
  type: WORK_ITEM_TYPE_ENUM_TEST_CASE,
};

const selectedIssuesMocks = {
  tasksOnly: [mockTask],
  testCasesOnly: [mockTestCase],
  issuesOnly: [mockIssue, mockIncident],
  tasksAndTestCases: [mockTask, mockTestCase],
  issuesAndTasks: [mockIssue, mockIncident, mockTask],
  issuesAndTestCases: [mockIssue, mockIncident, mockTestCase],
  issuesTasksAndTestCases: [mockIssue, mockIncident, mockTask, mockTestCase],
};

let getIssuesQueryCompleteResponse = getIssuesQueryResponse;
if (IS_EE) {
  getIssuesQueryCompleteResponse = cloneDeep(getIssuesQueryResponse);
  getIssuesQueryCompleteResponse.data.project.issues.nodes[0].blockingCount = 1;
  getIssuesQueryCompleteResponse.data.project.issues.nodes[0].healthStatus = null;
  getIssuesQueryCompleteResponse.data.project.issues.nodes[0].weight = 5;
  getIssuesQueryCompleteResponse.data.project.issues.nodes[0].epic = {
    id: 'gid://gitlab/Epic/1',
  };
}

const mockIssueResult = {
  id: mockIssue.iid,
  webUrl: `${mockDestinationProject.full_path}/issues/${mockIssue.iid}`,
};

const resolvedMutationWithoutErrorsMock = jest.fn().mockResolvedValue({
  data: {
    issueMove: {
      issue: mockIssueResult,
      errors: [],
    },
  },
});

const resolvedMutationWithErrorsMock = jest.fn().mockResolvedValue({
  data: {
    issueMove: {
      issue: mockIssueResult,
      errors: [{ message: mockMutationErrorMessage }],
    },
  },
});

const rejectedMutationMock = jest.fn().mockRejectedValue({});

const mockIssuesQueryResponse = jest.fn().mockResolvedValue(getIssuesQueryCompleteResponse);
const mockIssuesCountsQueryResponse = jest.fn().mockResolvedValue(getIssuesCountsQueryResponse);

describe('MoveIssuesButton', () => {
  Vue.use(VueApollo);

  let wrapper;
  let fakeApollo;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDropdown = () => wrapper.findComponent(IssuableMoveDropdown);
  const emitMoveIssuablesEvent = () => {
    findDropdown().vm.$emit('move-issuable', mockDestinationProject);
  };

  const createComponent = (data = {}, mutationResolverMock = rejectedMutationMock) => {
    fakeApollo = createMockApollo([
      [moveIssueMutation, mutationResolverMock],
      [getIssuesQuery, mockIssuesQueryResponse],
      [getIssuesCountsQuery, mockIssuesCountsQueryResponse],
    ]);

    fakeApollo.defaultClient.cache.writeQuery({
      query: getIssuesQuery,
      variables: {
        isProject: true,
        fullPath: mockDefaultProps.projectFullPath,
      },
      data: getIssuesQueryCompleteResponse.data,
    });

    fakeApollo.defaultClient.cache.writeQuery({
      query: getIssuesCountsQuery,
      variables: {
        isProject: true,
      },
      data: getIssuesCountsQueryResponse.data,
    });

    wrapper = shallowMount(MoveIssuesButton, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        ...mockDefaultProps,
      },
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(() => {
    // Needed due to a bug in Apollo: https://github.com/apollographql/apollo-client/issues/8900
    // eslint-disable-next-line no-console
    console.warn = jest.fn();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  describe('`Move selected` dropdown', () => {
    it('renders disabled by default', () => {
      createComponent();
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdown().attributes('disabled')).toBeDefined();
    });

    it.each`
      selectedIssuablesMock                          | disabled | status        | testMessage
      ${[]}                                          | ${true}  | ${'disabled'} | ${'nothing is selected'}
      ${selectedIssuesMocks.tasksOnly}               | ${true}  | ${'disabled'} | ${'only tasks are selected'}
      ${selectedIssuesMocks.testCasesOnly}           | ${true}  | ${'disabled'} | ${'only test cases are selected'}
      ${selectedIssuesMocks.issuesOnly}              | ${false} | ${'enabled'}  | ${'only issues are selected'}
      ${selectedIssuesMocks.tasksAndTestCases}       | ${true}  | ${'disabled'} | ${'tasks and test cases are selected'}
      ${selectedIssuesMocks.issuesAndTasks}          | ${false} | ${'enabled'}  | ${'issues and tasks are selected'}
      ${selectedIssuesMocks.issuesAndTestCases}      | ${false} | ${'enabled'}  | ${'issues and test cases are selected'}
      ${selectedIssuesMocks.issuesTasksAndTestCases} | ${false} | ${'enabled'}  | ${'issues and tasks and test cases are selected'}
    `('renders $status if $testMessage', async ({ selectedIssuablesMock, disabled }) => {
      createComponent({ selectedIssuables: selectedIssuablesMock });

      await nextTick();

      if (disabled) {
        expect(findDropdown().attributes('disabled')).toBeDefined();
      } else {
        expect(findDropdown().attributes('disabled')).toBeUndefined();
      }
    });
  });

  describe('warning message', () => {
    it.each`
      selectedIssuablesMock                          | warningExists | visibility       | message                                     | testMessage
      ${[]}                                          | ${false}      | ${'not visible'} | ${'empty'}                                  | ${'nothing is selected'}
      ${selectedIssuesMocks.tasksOnly}               | ${true}       | ${'visible'}     | ${'Tasks can not be moved.'}                | ${'only tasks are selected'}
      ${selectedIssuesMocks.testCasesOnly}           | ${true}       | ${'visible'}     | ${'Test cases can not be moved.'}           | ${'only test cases are selected'}
      ${selectedIssuesMocks.issuesOnly}              | ${false}      | ${'not visible'} | ${'empty'}                                  | ${'only issues are selected'}
      ${selectedIssuesMocks.tasksAndTestCases}       | ${true}       | ${'visible'}     | ${'Tasks and test cases can not be moved.'} | ${'tasks and test cases are selected'}
      ${selectedIssuesMocks.issuesAndTasks}          | ${true}       | ${'visible'}     | ${'Tasks can not be moved.'}                | ${'issues and tasks are selected'}
      ${selectedIssuesMocks.issuesAndTestCases}      | ${true}       | ${'visible'}     | ${'Test cases can not be moved.'}           | ${'issues and test cases are selected'}
      ${selectedIssuesMocks.issuesTasksAndTestCases} | ${true}       | ${'visible'}     | ${'Tasks and test cases can not be moved.'} | ${'issues and tasks and test cases are selected'}
    `(
      'is $visibility with `$message` message if $testMessage',
      async ({ selectedIssuablesMock, warningExists, message }) => {
        createComponent({ selectedIssuables: selectedIssuablesMock });

        await nextTick();

        const alert = findAlert();
        expect(alert.exists()).toBe(warningExists);

        if (warningExists) {
          expect(alert.text()).toBe(message);
          expect(alert.attributes('variant')).toBe('warning');
        }
      },
    );
  });

  describe('moveIssues method', () => {
    describe('changes the `Move selected` dropdown loading state', () => {
      it('keeps loading state to false when no issue is selected', async () => {
        createComponent();
        emitMoveIssuablesEvent();

        await nextTick();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('keeps loading state to false when only tasks are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksOnly });
        emitMoveIssuablesEvent();

        await nextTick();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('keeps loading state to false when only test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.testCasesOnly });
        emitMoveIssuablesEvent();

        await nextTick();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('keeps loading state to false when only tasks and test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksAndTestCases });
        emitMoveIssuablesEvent();

        await nextTick();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('sets loading state to true when issues are moving', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases });
        emitMoveIssuablesEvent();

        await nextTick();

        expect(findDropdown().props('moveInProgress')).toBe(true);
      });

      it('sets loading state to false when all mutations succeed', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await nextTick();
        await waitForPromises();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('sets loading state to false when a mutation returns errors', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithErrorsMock,
        );
        emitMoveIssuablesEvent();

        await nextTick();
        await waitForPromises();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });

      it('sets loading state to false when a mutation is rejected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases });
        emitMoveIssuablesEvent();

        await nextTick();
        await waitForPromises();

        expect(findDropdown().props('moveInProgress')).toBe(false);
      });
    });

    describe('handles events', () => {
      beforeEach(() => {
        jest.spyOn(issuableEventHub, '$emit');
      });

      it('does not emit any event when no issue is selected', async () => {
        createComponent();
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).not.toHaveBeenCalled();
      });

      it('does not emit any event when only tasks are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksOnly });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).not.toHaveBeenCalled();
      });

      it('does not emit any event when only test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.testCasesOnly });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).not.toHaveBeenCalled();
      });

      it('does not emit any event when only tasks and test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksAndTestCases });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).not.toHaveBeenCalled();
      });

      it('emits `issuables:bulkMoveStarted` when issues are moving', () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases });
        emitMoveIssuablesEvent();

        expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:bulkMoveStarted');
      });

      it('emits `issuables:bulkMoveEnded` when all mutations succeed', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:bulkMoveEnded');
      });

      it('emits `issuables:bulkMoveEnded` when a mutation returns errors', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:bulkMoveEnded');
      });

      it('emits `issuables:bulkMoveEnded` when a mutation is rejected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(issuableEventHub.$emit).toHaveBeenCalledWith('issuables:bulkMoveEnded');
      });
    });

    describe('shows errors', () => {
      it('does not create alerts or logs errors when no issue is selected', async () => {
        createComponent();
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not create alerts or logs errors when only tasks are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksOnly });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not create alerts or logs errors when only test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.testCasesOnly });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not create alerts or logs errors when only tasks and test cases are selected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.tasksAndTestCases });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('does not create alerts or logs errors when issues are moved without errors', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('creates an alert and logs errors when a mutation returns errors', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        // We're mocking two issues so it will log two errors
        expect(logError).toHaveBeenCalledTimes(2);
        expect(logError).toHaveBeenNthCalledWith(
          1,
          `Error moving issue. Error message: ${mockMutationErrorMessage}`,
        );
        expect(logError).toHaveBeenNthCalledWith(
          2,
          `Error moving issue. Error message: ${mockMutationErrorMessage}`,
        );

        // Only one alert is created even if multiple errors are reported
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was an error while moving the issues.',
        });
      });

      it('creates an alert but not logs errors when a mutation is rejected', async () => {
        createComponent({ selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases });
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was an error while moving the issues.',
        });
      });
    });

    describe('calls mutations', () => {
      it('does not call any mutation when no issue is selected', async () => {
        createComponent({}, resolvedMutationWithoutErrorsMock);
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(resolvedMutationWithoutErrorsMock).not.toHaveBeenCalled();
      });

      it('does not call any mutation when only tasks are selected', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.tasksOnly },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(resolvedMutationWithoutErrorsMock).not.toHaveBeenCalled();
      });

      it('does not call any mutation when only test cases are selected', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.testCasesOnly },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(resolvedMutationWithoutErrorsMock).not.toHaveBeenCalled();
      });

      it('does not call any mutation when only tasks and test cases are selected', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.tasksAndTestCases },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        expect(resolvedMutationWithoutErrorsMock).not.toHaveBeenCalled();
      });

      it('calls a mutation for every selected issue skipping tasks', async () => {
        createComponent(
          { selectedIssuables: selectedIssuesMocks.issuesTasksAndTestCases },
          resolvedMutationWithoutErrorsMock,
        );
        emitMoveIssuablesEvent();

        await waitForPromises();

        // We mock three elements but only two are valid issues since the task is skipped
        expect(resolvedMutationWithoutErrorsMock).toHaveBeenCalledTimes(2);
        expect(resolvedMutationWithoutErrorsMock).toHaveBeenNthCalledWith(1, {
          moveIssueInput: {
            projectPath: mockDefaultProps.projectFullPath,
            iid: selectedIssuesMocks.issuesTasksAndTestCases[0].iid.toString(),
            targetProjectPath: mockDestinationProject.full_path,
          },
        });

        expect(resolvedMutationWithoutErrorsMock).toHaveBeenNthCalledWith(2, {
          moveIssueInput: {
            projectPath: mockDefaultProps.projectFullPath,
            iid: selectedIssuesMocks.issuesTasksAndTestCases[1].iid.toString(),
            targetProjectPath: mockDestinationProject.full_path,
          },
        });
      });
    });
  });
});
