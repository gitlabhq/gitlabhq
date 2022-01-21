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
import RunnerEditButton from '~/runner/components/runner_edit_button.vue';
import RunnerDeleteModal from '~/runner/components/runner_delete_modal.vue';
import getGroupRunnersQuery from '~/runner/graphql/get_group_runners.query.graphql';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import runnerDeleteMutation from '~/runner/graphql/runner_delete.mutation.graphql';
import runnerActionsUpdateMutation from '~/runner/graphql/runner_actions_update.mutation.graphql';
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
  const runnerActionsUpdateMutationHandler = jest.fn();

  const findEditBtn = () => wrapper.findComponent(RunnerEditButton);
  const findToggleActiveBtn = () => wrapper.findByTestId('toggle-active-runner');
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
      apolloProvider: createMockApollo([
        [runnerDeleteMutation, runnerDeleteMutationHandler],
        [runnerActionsUpdateMutation, runnerActionsUpdateMutationHandler],
      ]),
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

    runnerActionsUpdateMutationHandler.mockResolvedValue({
      data: {
        runnerUpdate: {
          runner: mockRunner,
          errors: [],
        },
      },
    });
  });

  afterEach(() => {
    mockToastShow.mockReset();
    runnerDeleteMutationHandler.mockReset();
    runnerActionsUpdateMutationHandler.mockReset();

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

  describe('Toggle active action', () => {
    describe.each`
      state       | label       | icon       | isActive | newActiveValue
      ${'active'} | ${'Pause'}  | ${'pause'} | ${true}  | ${false}
      ${'paused'} | ${'Resume'} | ${'play'}  | ${false} | ${true}
    `('When the runner is $state', ({ label, icon, isActive, newActiveValue }) => {
      beforeEach(() => {
        createComponent({ active: isActive });
      });

      it(`Displays a ${icon} button`, () => {
        expect(findToggleActiveBtn().props('loading')).toBe(false);
        expect(findToggleActiveBtn().props('icon')).toBe(icon);
        expect(getTooltip(findToggleActiveBtn())).toBe(label);
        expect(findToggleActiveBtn().attributes('aria-label')).toBe(label);
      });

      it(`After clicking the ${icon} button, the button has a loading state`, async () => {
        await findToggleActiveBtn().vm.$emit('click');

        expect(findToggleActiveBtn().props('loading')).toBe(true);
      });

      it(`After the ${icon} button is clicked, stale tooltip is removed`, async () => {
        await findToggleActiveBtn().vm.$emit('click');

        expect(getTooltip(findToggleActiveBtn())).toBe('');
        expect(findToggleActiveBtn().attributes('aria-label')).toBe('');
      });

      describe(`When clicking on the ${icon} button`, () => {
        it(`The apollo mutation to set active to ${newActiveValue} is called`, async () => {
          expect(runnerActionsUpdateMutationHandler).toHaveBeenCalledTimes(0);

          await findToggleActiveBtn().vm.$emit('click');

          expect(runnerActionsUpdateMutationHandler).toHaveBeenCalledTimes(1);
          expect(runnerActionsUpdateMutationHandler).toHaveBeenCalledWith({
            input: {
              id: mockRunner.id,
              active: newActiveValue,
            },
          });
        });

        it('The button does not have a loading state after the mutation occurs', async () => {
          await findToggleActiveBtn().vm.$emit('click');

          expect(findToggleActiveBtn().props('loading')).toBe(true);

          await waitForPromises();

          expect(findToggleActiveBtn().props('loading')).toBe(false);
        });
      });

      describe('When update fails', () => {
        describe('On a network error', () => {
          const mockErrorMsg = 'Update error!';

          beforeEach(async () => {
            runnerActionsUpdateMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

            await findToggleActiveBtn().vm.$emit('click');
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
        });

        describe('On a validation error', () => {
          const mockErrorMsg = 'Runner not found!';
          const mockErrorMsg2 = 'User not allowed!';

          beforeEach(async () => {
            runnerActionsUpdateMutationHandler.mockResolvedValue({
              data: {
                runnerUpdate: {
                  runner: mockRunner,
                  errors: [mockErrorMsg, mockErrorMsg2],
                },
              },
            });

            await findToggleActiveBtn().vm.$emit('click');
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

    it('Does not render the runner toggle active button when user cannot update', () => {
      createComponent({
        userPermissions: {
          ...mockRunner.userPermissions,
          updateRunner: false,
        },
      });

      expect(findToggleActiveBtn().exists()).toBe(false);
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
      beforeEach(() => {
        findRunnerDeleteModal().vm.$emit('primary');
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

        beforeEach(() => {
          runnerDeleteMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

          findRunnerDeleteModal().vm.$emit('primary');
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

        beforeEach(() => {
          runnerDeleteMutationHandler.mockResolvedValue({
            data: {
              runnerDelete: {
                errors: [mockErrorMsg, mockErrorMsg2],
              },
            },
          });

          findRunnerDeleteModal().vm.$emit('primary');
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
