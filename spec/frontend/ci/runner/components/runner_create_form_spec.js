import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import { DEFAULT_ACCESS_LEVEL } from '~/ci/runner/constants';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { runnerCreateResult } from '../mock_data';

jest.mock('~/ci/runner/sentry_utils');

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

const defaultRunnerModel = {
  description: '',
  accessLevel: DEFAULT_ACCESS_LEVEL,
  paused: false,
  maintenanceNote: '',
  maximumTimeout: '',
  runUntagged: false,
  tagList: '',
};

Vue.use(VueApollo);

describe('RunnerCreateForm', () => {
  let wrapper;
  let runnerCreateHandler;

  const findForm = () => wrapper.findComponent(GlForm);
  const findRunnerFormFields = () => wrapper.findComponent(RunnerFormFields);
  const findSubmitBtn = () => wrapper.find('[type="submit"]');

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCreateForm, {
      apolloProvider: createMockApollo([[runnerCreateMutation, runnerCreateHandler]]),
    });
  };

  beforeEach(() => {
    runnerCreateHandler = jest.fn().mockResolvedValue(runnerCreateResult);

    createComponent();
  });

  it('shows default runner values', () => {
    expect(findRunnerFormFields().props('value')).toEqual(defaultRunnerModel);
  });

  it('shows a submit button', () => {
    expect(findSubmitBtn().exists()).toBe(true);
  });

  describe('when user submits', () => {
    let preventDefault;

    beforeEach(() => {
      preventDefault = jest.fn();

      findRunnerFormFields().vm.$emit('input', {
        ...defaultRunnerModel,
        description: 'My runner',
        maximumTimeout: 0,
        tagList: 'tag1, tag2',
      });
    });

    describe('immediately after submit', () => {
      beforeEach(() => {
        findForm().vm.$emit('submit', { preventDefault });
      });

      it('prevents default form submission', () => {
        expect(preventDefault).toHaveBeenCalledTimes(1);
      });

      it('shows a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(true);
      });

      it('saves runner', async () => {
        expect(runnerCreateHandler).toHaveBeenCalledWith({
          input: {
            ...defaultRunnerModel,
            description: 'My runner',
            maximumTimeout: 0,
            tagList: ['tag1', 'tag2'],
          },
        });
      });
    });

    describe('when saved successfully', () => {
      beforeEach(async () => {
        findForm().vm.$emit('submit', { preventDefault });
        await waitForPromises();
      });

      it('emits "saved" result', async () => {
        expect(wrapper.emitted('saved')[0]).toEqual([mockCreatedRunner]);
      });

      it('does not show a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(false);
      });
    });

    describe('when a server error occurs', () => {
      const error = new Error('Error!');

      beforeEach(async () => {
        runnerCreateHandler.mockRejectedValue(error);

        findForm().vm.$emit('submit', { preventDefault });
        await waitForPromises();
      });

      it('emits "error" result', async () => {
        expect(wrapper.emitted('error')[0]).toEqual([error]);
      });

      it('does not show a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(false);
      });

      it('reports error', () => {
        expect(captureException).toHaveBeenCalledTimes(1);
        expect(captureException).toHaveBeenCalledWith({
          component: 'RunnerCreateForm',
          error,
        });
      });
    });

    describe('when a validation error occurs', () => {
      const errorMsg1 = 'Issue1!';
      const errorMsg2 = 'Issue2!';

      beforeEach(async () => {
        runnerCreateHandler.mockResolvedValue({
          data: {
            runnerCreate: {
              errors: [errorMsg1, errorMsg2],
              runner: null,
            },
          },
        });

        findForm().vm.$emit('submit', { preventDefault });
        await waitForPromises();
      });

      it('emits "error" results', async () => {
        expect(wrapper.emitted('error')[0]).toEqual([new Error(`${errorMsg1} ${errorMsg2}`)]);
      });

      it('does not show a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(false);
      });

      it('does not report error', () => {
        expect(captureException).not.toHaveBeenCalled();
      });
    });
  });
});
