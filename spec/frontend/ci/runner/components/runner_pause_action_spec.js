import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import runnerTogglePausedMutation from '~/ci/runner/graphql/shared/runner_toggle_paused.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import { createAlert } from '~/alert';

import RunnerPauseAction from '~/ci/runner/components/runner_pause_action.vue';
import { allRunnersData } from '../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

describe('RunnerPauseAction', () => {
  let wrapper;
  let runnerTogglePausedHandler;

  const findBtn = () => wrapper.find('button');

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    const { runner, ...propsData } = props;

    wrapper = mountFn(RunnerPauseAction, {
      propsData: {
        runner: {
          id: mockRunner.id,
          paused: mockRunner.paused,
          ...runner,
        },
        ...propsData,
      },
      apolloProvider: createMockApollo([[runnerTogglePausedMutation, runnerTogglePausedHandler]]),
      scopedSlots: {
        default: '<button :disabled="props.loading" @click="props.onClick"/>',
      },
    });
  };

  const clickAndWait = async () => {
    findBtn().trigger('click');
    await waitForPromises();
  };

  beforeEach(() => {
    runnerTogglePausedHandler = jest.fn().mockImplementation(({ input }) => {
      return Promise.resolve({
        data: {
          runnerUpdate: {
            runner: {
              id: input.id,
              paused: !input.paused,
            },
            errors: [],
          },
        },
      });
    });

    createComponent();
  });

  describe('Pause/Resume action', () => {
    describe.each`
      runnerState | isPaused | newPausedValue
      ${'paused'} | ${true}  | ${false}
      ${'active'} | ${false} | ${true}
    `('When the runner is $runnerState', ({ isPaused, newPausedValue }) => {
      beforeEach(() => {
        createComponent({
          props: {
            runner: {
              paused: isPaused,
            },
          },
        });
      });

      it('Displays slot contents', () => {
        expect(findBtn().exists()).toBe(true);
      });

      it('The mutation has not been called', () => {
        expect(runnerTogglePausedHandler).not.toHaveBeenCalled();
      });

      describe('Immediately after the action is triggered', () => {
        it('The button has a loading state', async () => {
          await findBtn().trigger('click');

          expect(findBtn().attributes('disabled')).toBe('disabled');
        });
      });

      describe('After the action is triggered', () => {
        beforeEach(async () => {
          await clickAndWait();
        });

        it(`The mutation to that sets "paused" to ${newPausedValue} is called`, () => {
          expect(runnerTogglePausedHandler).toHaveBeenCalledTimes(1);
          expect(runnerTogglePausedHandler).toHaveBeenCalledWith({
            input: {
              id: mockRunner.id,
              paused: newPausedValue,
            },
          });
        });

        it('The button does not have a loading state', () => {
          expect(findBtn().attributes('disabled')).toBeUndefined();
        });

        it('The button emits "done"', () => {
          expect(wrapper.emitted('done')).toHaveLength(1);
        });
      });

      describe('When update fails', () => {
        describe('On a network error', () => {
          const mockErrorMsg = 'Update error!';

          beforeEach(async () => {
            runnerTogglePausedHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

            await clickAndWait();
          });

          it('error is reported to sentry', () => {
            expect(captureException).toHaveBeenCalledWith({
              error: new Error(mockErrorMsg),
              component: 'RunnerPauseAction',
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
            runnerTogglePausedHandler.mockResolvedValueOnce({
              data: {
                runnerUpdate: {
                  runner: {
                    id: mockRunner.id,
                    paused: isPaused,
                  },
                  errors: [mockErrorMsg, mockErrorMsg2],
                },
              },
            });

            await clickAndWait();
          });

          it('error is reported to sentry', () => {
            expect(captureException).toHaveBeenCalledWith({
              error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
              component: 'RunnerPauseAction',
            });
          });

          it('error is shown to the user', () => {
            expect(createAlert).toHaveBeenCalledTimes(1);
          });
        });
      });
    });
  });
});
