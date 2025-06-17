import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import RunnerToggleAssignButton from '~/ci/runner/project_runners_settings/components/runner_toggle_assign_button.vue';
import runnerAssignToProjectMutation from '~/ci/runner/graphql/list/runner_assign_to_project.mutation.graphql';
import runnerUnassignFromProjectMutation from '~/ci/runner/graphql/list/runner_unassign_from_project.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';

Vue.use(VueApollo);

jest.mock('~/ci/runner/sentry_utils');

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
    case                           | assigns  | icon        | tooltip                    | handler                          | doneMessage                                               | errorMessage
    ${'when assigning a runner'}   | ${true}  | ${'link'}   | ${'Assign to project'}     | ${() => assignMutationHandler}   | ${'Runner #1 (abc123) was assigned to this project.'}     | ${'Failed to assign runner to project.'}
    ${'when unassigning a runner'} | ${false} | ${'unlink'} | ${'Unassign from project'} | ${() => unassignMutationHandler} | ${'Runner #1 (abc123) was unassigned from this project.'} | ${'Failed to unassign runner from project.'}
  `('$case', ({ assigns, icon, tooltip, handler, doneMessage, errorMessage }) => {
    beforeEach(() => {
      createComponent({
        props: { assigns },
      });
    });

    it('renders button', () => {
      expect(findButton().props('loading')).toBe(false);
      expect(findButton().props('icon')).toBe(icon);
      expect(getTooltipValue()).toBe(tooltip);
    });

    it('calls assign mutation when clicked', () => {
      findButton().vm.$emit('click');

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
      await findButton().vm.$emit('click');

      expect(findButton().props('loading')).toBe(true);

      await waitForPromises();

      expect(findButton().props('loading')).toBe(false);
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
      });

      it('handles network errors', async () => {
        handler().mockRejectedValue(new Error('Network error'));

        findButton().vm.$emit('click');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([
          [{ error: new Error('Network error'), message: errorMessage }],
        ]);

        expect(captureException).toHaveBeenCalled();
      });
    });
  });
});
