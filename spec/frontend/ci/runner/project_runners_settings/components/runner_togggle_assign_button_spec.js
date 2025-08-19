import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

import RunnerToggleAssignButton from '~/ci/runner/project_runners_settings/components/runner_toggle_assign_button.vue';
import runnerAssignToProjectMutation from '~/ci/runner/graphql/list/runner_assign_to_project.mutation.graphql';
import runnerUnassignFromProjectMutation from '~/ci/runner/graphql/list/runner_unassign_from_project.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';

Vue.use(VueApollo);

jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('RunnerToggleAssignButton', () => {
  let wrapper;
  let assignMutationHandler;
  let unassignMutationHandler;

  const mockRunner = {
    id: 'gid://gitlab/Ci::Runner/1',
    shortSha: 'abc123',
    description: 'Test runner',
  };

  const projectFullPath = 'group/project';

  const findButton = () => wrapper.findComponent(GlButton);
  const getTooltipValue = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createComponent = ({ props } = {}) => {
    const mockApollo = createMockApollo([
      [runnerAssignToProjectMutation, assignMutationHandler],
      [runnerUnassignFromProjectMutation, unassignMutationHandler],
    ]);

    wrapper = shallowMount(RunnerToggleAssignButton, {
      propsData: {
        projectFullPath,
        runner: mockRunner,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      apolloProvider: mockApollo,
    });
  };

  beforeEach(() => {
    assignMutationHandler = jest
      .fn()
      .mockResolvedValue({ data: { runnerAssignToProject: { errors: [] } } });

    unassignMutationHandler = jest
      .fn()
      .mockResolvedValue({ data: { runnerUnassignFromProject: { errors: [] } } });
  });

  describe.each`
    case                           | assigns  | confirms | variant      | icon        | tooltip                    | handler                          | doneMessage                                               | errorMessage
    ${'when assigning a runner'}   | ${true}  | ${false} | ${'default'} | ${'link'}   | ${'Assign to project'}     | ${() => assignMutationHandler}   | ${'Runner #1 (abc123) was assigned to this project.'}     | ${'Failed to assign runner to project.'}
    ${'when unassigning a runner'} | ${false} | ${true}  | ${'danger'}  | ${'unlink'} | ${'Unassign from project'} | ${() => unassignMutationHandler} | ${'Runner #1 (abc123) was unassigned from this project.'} | ${'Failed to unassign runner from project.'}
  `(
    '$case',
    ({ assigns, confirms, variant, icon, tooltip, handler, doneMessage, errorMessage }) => {
      beforeEach(() => {
        createComponent({
          props: { assigns },
        });

        confirmAction.mockResolvedValue(true);
      });

      it('renders button', () => {
        expect(findButton().props('loading')).toBe(false);
        expect(findButton().props('variant')).toBe(variant);
        expect(findButton().props('icon')).toBe(icon);
        expect(findButton().attributes('aria-label')).toBe(tooltip);
        expect(getTooltipValue()).toBe(tooltip);
      });

      it('calls assign mutation when clicked', async () => {
        findButton().vm.$emit('click');
        await waitForPromises();

        if (confirms) {
          expect(confirmAction).toHaveBeenCalledTimes(1);
          expect(confirmAction).toHaveBeenCalledWith(
            expect.stringContaining('Are you sure you want to continue?'),
            expect.objectContaining({ title: 'Unassign runner #1 (abc123)?' }),
          );
        } else {
          expect(confirmAction).not.toHaveBeenCalled();
        }

        expect(handler()).toHaveBeenCalledTimes(1);
        expect(handler()).toHaveBeenCalledWith({
          runnerId: mockRunner.id,
          projectPath: projectFullPath,
        });
      });

      it('emits done event with success message after successful mutation', async () => {
        findButton().vm.$emit('click');
        await waitForPromises();

        expect(wrapper.emitted('done')).toEqual([[{ message: doneMessage }]]);
      });

      it('shows loading state while mutation is in progress', async () => {
        const pending = () => new Promise(() => {});
        handler().mockImplementation(pending);

        findButton().vm.$emit('click');
        await waitForPromises();

        expect(findButton().props('loading')).toBe(true);
      });

      describe('error handling', () => {
        it('handles mutation errors', async () => {
          handler().mockResolvedValue({
            data: {
              runnerAssignToProject: { errors: ['Something went wrong'] },
              runnerUnassignFromProject: { errors: ['Something went wrong'] },
            },
          });

          findButton().vm.$emit('click');
          await waitForPromises();

          expect(wrapper.emitted('error')).toEqual([
            [{ error: new Error('Something went wrong'), message: errorMessage }],
          ]);

          expect(captureException).toHaveBeenCalled();
          expect(findButton().props('loading')).toBe(false);
        });

        it('handles network errors', async () => {
          handler().mockRejectedValue(new Error('Network error'));

          findButton().vm.$emit('click');
          await waitForPromises();

          expect(wrapper.emitted('error')).toEqual([
            [{ error: new Error('Network error'), message: errorMessage }],
          ]);

          expect(captureException).toHaveBeenCalled();
          expect(findButton().props('loading')).toBe(false);
        });
      });
    },
  );

  describe('when unassigning a runner with no confirmation', () => {
    beforeEach(() => {
      createComponent({
        props: { assigns: false },
      });

      confirmAction.mockResolvedValue(false);
    });

    it('does not call assign mutation when clicked', async () => {
      findButton().vm.$emit('click');

      await waitForPromises();

      expect(unassignMutationHandler).not.toHaveBeenCalled();
      expect(findButton().props('loading')).toBe(false);
    });
  });
});
