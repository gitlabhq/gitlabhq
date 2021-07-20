import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import RunnerActionCell from '~/runner/components/cells/runner_actions_cell.vue';
import getRunnersQuery from '~/runner/graphql/get_runners.query.graphql';
import runnerDeleteMutation from '~/runner/graphql/runner_delete.mutation.graphql';
import runnerUpdateMutation from '~/runner/graphql/runner_update.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';
import { runnerData } from '../../mock_data';

const mockRunner = runnerData.data.runner;

const getRunnersQueryName = getRunnersQuery.definitions[0].name.value;

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

describe('RunnerTypeCell', () => {
  let wrapper;
  const runnerDeleteMutationHandler = jest.fn();
  const runnerUpdateMutationHandler = jest.fn();

  const findEditBtn = () => wrapper.findByTestId('edit-runner');
  const findToggleActiveBtn = () => wrapper.findByTestId('toggle-active-runner');
  const findDeleteBtn = () => wrapper.findByTestId('delete-runner');

  const createComponent = ({ active = true } = {}, options) => {
    wrapper = extendedWrapper(
      shallowMount(RunnerActionCell, {
        propsData: {
          runner: {
            id: mockRunner.id,
            active,
          },
        },
        localVue,
        apolloProvider: createMockApollo([
          [runnerDeleteMutation, runnerDeleteMutationHandler],
          [runnerUpdateMutation, runnerUpdateMutationHandler],
        ]),
        ...options,
      }),
    );
  };

  beforeEach(() => {
    runnerDeleteMutationHandler.mockResolvedValue({
      data: {
        runnerDelete: {
          errors: [],
        },
      },
    });

    runnerUpdateMutationHandler.mockResolvedValue({
      data: {
        runnerUpdate: {
          runner: runnerData.data.runner,
          errors: [],
        },
      },
    });
  });

  afterEach(() => {
    runnerDeleteMutationHandler.mockReset();
    runnerUpdateMutationHandler.mockReset();

    wrapper.destroy();
  });

  it('Displays the runner edit link with the correct href', () => {
    createComponent();

    expect(findEditBtn().attributes('href')).toBe('/admin/runners/1');
  });

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
      expect(findToggleActiveBtn().attributes('title')).toBe(label);
      expect(findToggleActiveBtn().attributes('aria-label')).toBe(label);
    });

    it(`After clicking the ${icon} button, the button has a loading state`, async () => {
      await findToggleActiveBtn().vm.$emit('click');

      expect(findToggleActiveBtn().props('loading')).toBe(true);
    });

    it(`After the ${icon} button is clicked, stale tooltip is removed`, async () => {
      await findToggleActiveBtn().vm.$emit('click');

      expect(findToggleActiveBtn().attributes('title')).toBe('');
      expect(findToggleActiveBtn().attributes('aria-label')).toBe('');
    });

    describe(`When clicking on the ${icon} button`, () => {
      it(`The apollo mutation to set active to ${newActiveValue} is called`, async () => {
        expect(runnerUpdateMutationHandler).toHaveBeenCalledTimes(0);

        await findToggleActiveBtn().vm.$emit('click');

        expect(runnerUpdateMutationHandler).toHaveBeenCalledTimes(1);
        expect(runnerUpdateMutationHandler).toHaveBeenCalledWith({
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
          runnerUpdateMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

          await findToggleActiveBtn().vm.$emit('click');
        });

        it('error is reported to sentry', () => {
          expect(captureException).toHaveBeenCalledWith({
            error: new Error(`Network error: ${mockErrorMsg}`),
            component: 'RunnerActionsCell',
          });
        });

        it('error is shown to the user', () => {
          expect(createFlash).toHaveBeenCalledTimes(1);
        });
      });

      describe('On a validation error', () => {
        const mockErrorMsg = 'Runner not found!';
        const mockErrorMsg2 = 'User not allowed!';

        beforeEach(async () => {
          runnerUpdateMutationHandler.mockResolvedValue({
            data: {
              runnerUpdate: {
                runner: runnerData.data.runner,
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
          expect(createFlash).toHaveBeenCalledTimes(1);
        });
      });
    });
  });

  describe('When the user clicks a runner', () => {
    beforeEach(() => {
      jest.spyOn(window, 'confirm');

      createComponent();
    });

    afterEach(() => {
      window.confirm.mockRestore();
    });

    describe('When the user confirms deletion', () => {
      beforeEach(async () => {
        window.confirm.mockReturnValue(true);
        await findDeleteBtn().vm.$emit('click');
      });

      it('The user sees a confirmation alert', () => {
        expect(window.confirm).toHaveBeenCalledTimes(1);
        expect(window.confirm).toHaveBeenCalledWith(expect.any(String));
      });

      it('The delete mutation is called correctly', () => {
        expect(runnerDeleteMutationHandler).toHaveBeenCalledTimes(1);
        expect(runnerDeleteMutationHandler).toHaveBeenCalledWith({
          input: { id: mockRunner.id },
        });
      });

      it('When delete mutation is called, current runners are refetched', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate');

        await findDeleteBtn().vm.$emit('click');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: runnerDeleteMutation,
          variables: {
            input: {
              id: mockRunner.id,
            },
          },
          awaitRefetchQueries: true,
          refetchQueries: [getRunnersQueryName],
        });
      });

      it('The delete button does not have a loading state', () => {
        expect(findDeleteBtn().props('loading')).toBe(false);
        expect(findDeleteBtn().attributes('title')).toBe('Remove');
      });

      it('After the delete button is clicked, loading state is shown', async () => {
        await findDeleteBtn().vm.$emit('click');

        expect(findDeleteBtn().props('loading')).toBe(true);
      });

      it('After the delete button is clicked, stale tooltip is removed', async () => {
        await findDeleteBtn().vm.$emit('click');

        expect(findDeleteBtn().attributes('title')).toBe('');
      });

      describe('When delete fails', () => {
        describe('On a network error', () => {
          const mockErrorMsg = 'Delete error!';

          beforeEach(async () => {
            runnerDeleteMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

            await findDeleteBtn().vm.$emit('click');
          });

          it('error is reported to sentry', () => {
            expect(captureException).toHaveBeenCalledWith({
              error: new Error(`Network error: ${mockErrorMsg}`),
              component: 'RunnerActionsCell',
            });
          });

          it('error is shown to the user', () => {
            expect(createFlash).toHaveBeenCalledTimes(1);
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

            await findDeleteBtn().vm.$emit('click');
          });

          it('error is reported to sentry', () => {
            expect(captureException).toHaveBeenCalledWith({
              error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
              component: 'RunnerActionsCell',
            });
          });

          it('error is shown to the user', () => {
            expect(createFlash).toHaveBeenCalledTimes(1);
          });
        });
      });
    });

    describe('When the user does not confirm deletion', () => {
      beforeEach(async () => {
        window.confirm.mockReturnValue(false);
        await findDeleteBtn().vm.$emit('click');
      });

      it('The user sees a confirmation alert', () => {
        expect(window.confirm).toHaveBeenCalledTimes(1);
      });

      it('The delete mutation is not called', () => {
        expect(runnerDeleteMutationHandler).toHaveBeenCalledTimes(0);
      });

      it('The delete button does not have a loading state', () => {
        expect(findDeleteBtn().props('loading')).toBe(false);
        expect(findDeleteBtn().attributes('title')).toBe('Remove');
      });
    });
  });
});
