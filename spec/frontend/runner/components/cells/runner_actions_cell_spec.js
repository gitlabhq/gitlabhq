import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createAlert } from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import { captureException } from '~/runner/sentry_utils';
import RunnerActionCell from '~/runner/components/cells/runner_actions_cell.vue';
import RunnerPauseButton from '~/runner/components/runner_pause_button.vue';
import RunnerEditButton from '~/runner/components/runner_edit_button.vue';
import RunnerDeleteModal from '~/runner/components/runner_delete_modal.vue';
import getGroupRunnersQuery from '~/runner/graphql/get_group_runners.query.graphql';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import runnerDeleteMutation from '~/runner/graphql/runner_delete.mutation.graphql';
import { runnersData } from '../../mock_data';

const mockRunner = runnersData.data.runners.nodes[0];

const getRunnersQueryName = getRunnersQuery.definitions[0].name.value;
const getGroupRunnersQueryName = getGroupRunnersQuery.definitions[0].name.value;

Vue.use(VueApollo);

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

describe('RunnerTypeCell', () => {
  let wrapper;

  const mockToastShow = jest.fn();
  const runnerDeleteMutationHandler = jest.fn();

  const findEditBtn = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseBtn = () => wrapper.findComponent(RunnerPauseButton);
  const findRunnerDeleteModal = () => wrapper.findComponent(RunnerDeleteModal);
  const findDeleteBtn = () => wrapper.findByTestId('delete-runner');
  const getTooltip = (w) => getBinding(w.element, 'gl-tooltip')?.value;

  const createComponent = (runner = {}, options) => {
    wrapper = shallowMountExtended(RunnerActionCell, {
      propsData: {
        runner: {
          id: mockRunner.id,
          shortSha: mockRunner.shortSha,
          editAdminUrl: mockRunner.editAdminUrl,
          userPermissions: mockRunner.userPermissions,
          active: mockRunner.active,
          ...runner,
        },
      },
      apolloProvider: createMockApollo([[runnerDeleteMutation, runnerDeleteMutationHandler]]),
      directives: {
        GlTooltip: createMockDirective(),
        GlModal: createMockDirective(),
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      ...options,
    });
  };

  beforeEach(() => {
    runnerDeleteMutationHandler.mockResolvedValue({
      data: {
        runnerDelete: {
          errors: [],
        },
      },
    });
  });

  afterEach(() => {
    mockToastShow.mockReset();
    runnerDeleteMutationHandler.mockReset();

    wrapper.destroy();
  });

  describe('Edit Action', () => {
    it('Displays the runner edit link with the correct href', () => {
      createComponent();

      expect(findEditBtn().attributes('href')).toBe(mockRunner.editAdminUrl);
    });

    it('Does not render the runner edit link when user cannot update', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          updateRunner: false,
        },
      });

      expect(findEditBtn().exists()).toBe(false);
    });

    it('Does not render the runner edit link when editAdminUrl is not provided', () => {
      createComponent({
        editAdminUrl: null,
      });

      expect(findEditBtn().exists()).toBe(false);
    });
  });

  describe('Pause action', () => {
    it('Renders a compact pause button', () => {
      createComponent();

      expect(findRunnerPauseBtn().props('compact')).toBe(true);
    });

    it('Does not render the runner pause button when user cannot update', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          updateRunner: false,
        },
      });

      expect(findRunnerPauseBtn().exists()).toBe(false);
    });
  });

  describe('Delete action', () => {
    beforeEach(() => {
      createComponent(
        {},
        {
          stubs: { RunnerDeleteModal },
        },
      );
    });

    it('Renders delete button', () => {
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('Delete button opens delete modal', () => {
      const modalId = getBinding(findDeleteBtn().element, 'gl-modal').value;

      expect(findRunnerDeleteModal().attributes('modal-id')).toBeDefined();
      expect(findRunnerDeleteModal().attributes('modal-id')).toBe(modalId);
    });

    it('Delete modal shows the runner name', () => {
      expect(findRunnerDeleteModal().props('runnerName')).toBe(
        `#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha})`,
      );
    });
    it('The delete button does not have a loading icon', () => {
      expect(findDeleteBtn().props('loading')).toBe(false);
      expect(getTooltip(findDeleteBtn())).toBe('Delete runner');
    });

    it('When delete mutation is called, current runners are refetched', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate');

      findRunnerDeleteModal().vm.$emit('primary');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: runnerDeleteMutation,
        variables: {
          input: {
            id: mockRunner.id,
          },
        },
        awaitRefetchQueries: true,
        refetchQueries: [getRunnersQueryName, getGroupRunnersQueryName],
      });
    });

    it('Does not render the runner delete button when user cannot delete', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          deleteRunner: false,
        },
      });

      expect(findDeleteBtn().exists()).toBe(false);
      expect(findRunnerDeleteModal().exists()).toBe(false);
    });

    describe('When delete is clicked', () => {
      beforeEach(async () => {
        findRunnerDeleteModal().vm.$emit('primary');
        await waitForPromises();
      });

      it('The delete mutation is called correctly', () => {
        expect(runnerDeleteMutationHandler).toHaveBeenCalledTimes(1);
        expect(runnerDeleteMutationHandler).toHaveBeenCalledWith({
          input: { id: mockRunner.id },
        });
      });

      it('The delete button has a loading icon', () => {
        expect(findDeleteBtn().props('loading')).toBe(true);
        expect(getTooltip(findDeleteBtn())).toBe('');
      });

      it('The toast notification is shown', () => {
        expect(mockToastShow).toHaveBeenCalledTimes(1);
        expect(mockToastShow).toHaveBeenCalledWith(
          expect.stringContaining(`#${getIdFromGraphQLId(mockRunner.id)} (${mockRunner.shortSha})`),
        );
      });
    });

    describe('When delete fails', () => {
      describe('On a network error', () => {
        const mockErrorMsg = 'Delete error!';

        beforeEach(async () => {
          runnerDeleteMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

          findRunnerDeleteModal().vm.$emit('primary');
          await waitForPromises();
        });

        it('error is reported to sentry', () => {
          expect(captureException).toHaveBeenCalledWith({
            error: new Error(`Network error: ${mockErrorMsg}`),
            component: 'RunnerActionsCell',
          });
        });

        it('error is shown to the user', () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
        });

        it('toast notification is not shown', () => {
          expect(mockToastShow).not.toHaveBeenCalled();
        });
      });

      describe('On a validation error', () => {
        const mockErrorMsg = 'Runner not found!';
        const mockErrorMsg2 = 'User not allowed!';

        beforeEach(async () => {
          runnerDeleteMutationHandler.mockResolvedValue({
            data: {
              runnerDelete: {
                errors: [mockErrorMsg, mockErrorMsg2],
              },
            },
          });

          findRunnerDeleteModal().vm.$emit('primary');
          await waitForPromises();
        });

        it('error is reported to sentry', () => {
          expect(captureException).toHaveBeenCalledWith({
            error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
            component: 'RunnerActionsCell',
          });
        });

        it('error is shown to the user', () => {
          expect(createAlert).toHaveBeenCalledTimes(1);
        });
      });
    });
  });
});
