import Vue from 'vue';
import { GlForm } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import {
  DEFAULT_ACCESS_LEVEL,
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_CREATE_ERROR,
} from '~/ci/runner/constants';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { runnerCreateResult } from '../mock_data';

jest.mock('~/ci/runner/sentry_utils');

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

const defaultRunnerModel = {
  runnerType: INSTANCE_TYPE,
  description: '',
  accessLevel: DEFAULT_ACCESS_LEVEL,
  paused: false,
  maintenanceNote: '',
  maximumTimeout: '',
  runUntagged: false,
  locked: false,
  tagList: '',
};

Vue.use(VueApollo);

describe('RunnerCreateForm', () => {
  let wrapper;
  let runnerCreateHandler;

  const findForm = () => wrapper.findComponent(GlForm);
  const findRunnerFormFields = () => wrapper.findComponent(RunnerFormFields);
  const findSubmitBtn = () => wrapper.find('[type="submit"]');

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(RunnerCreateForm, {
      propsData: {
        runnerType: INSTANCE_TYPE,
        ...props,
      },
      apolloProvider: createMockApollo([[runnerCreateMutation, runnerCreateHandler]]),
    });
  };

  beforeEach(() => {
    runnerCreateHandler = jest.fn().mockResolvedValue(runnerCreateResult);
  });

  it('shows default runner values', () => {
    createComponent();

    expect(findRunnerFormFields().props('value')).toEqual(defaultRunnerModel);
    expect(findRunnerFormFields().props('runnerType')).toEqual(INSTANCE_TYPE);
  });

  it('shows a submit button', () => {
    createComponent();

    expect(findSubmitBtn().exists()).toBe(true);
  });

  describe.each`
    typeName                | props                                                                 | scopeData
    ${'an instance runner'} | ${{ runnerType: INSTANCE_TYPE }}                                      | ${{ runnerType: INSTANCE_TYPE }}
    ${'a group runner'}     | ${{ runnerType: GROUP_TYPE, groupId: 'gid://gitlab/Group/72' }}       | ${{ runnerType: GROUP_TYPE, groupId: 'gid://gitlab/Group/72' }}
    ${'a project runner'}   | ${{ runnerType: PROJECT_TYPE, projectId: 'gid://gitlab/Project/42' }} | ${{ runnerType: PROJECT_TYPE, projectId: 'gid://gitlab/Project/42' }}
  `('when user submits $typeName', ({ props, scopeData }) => {
    let preventDefault;

    beforeEach(() => {
      createComponent({ props });

      preventDefault = jest.fn();

      findRunnerFormFields().vm.$emit('input', {
        ...defaultRunnerModel,
        runnerType: props.runnerType,
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

      it('saves runner', () => {
        expect(runnerCreateHandler).toHaveBeenCalledWith({
          input: {
            ...defaultRunnerModel,
            ...scopeData,
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

      it('emits "saved" result', () => {
        expect(wrapper.emitted('saved')[0]).toEqual([mockCreatedRunner]);
      });

      it('maintains a saving state before navigating away', () => {
        expect(findSubmitBtn().props('loading')).toBe(true);
      });
    });

    describe('when a server error occurs', () => {
      const error = new Error('Error!');

      beforeEach(async () => {
        runnerCreateHandler.mockRejectedValue(error);

        findForm().vm.$emit('submit', { preventDefault });
        await waitForPromises();
      });

      it('emits "error" result', () => {
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

      it('emits "error" results', () => {
        expect(wrapper.emitted('error')[0]).toEqual([new Error(`${errorMsg1} ${errorMsg2}`)]);
      });

      it('does not show a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(false);
      });

      it('does not report error', () => {
        expect(captureException).not.toHaveBeenCalled();
      });
    });

    describe('when no runner information is returned', () => {
      beforeEach(async () => {
        runnerCreateHandler.mockResolvedValue({
          data: {
            runnerCreate: {
              errors: [],
              runner: null,
            },
          },
        });

        findForm().vm.$emit('submit', { preventDefault });
        await waitForPromises();
      });

      it('emits "error" result', () => {
        expect(wrapper.emitted('error')[0]).toEqual([new TypeError(I18N_CREATE_ERROR)]);
      });

      it('does not show a saving state', () => {
        expect(findSubmitBtn().props('loading')).toBe(false);
      });

      it('reports error', () => {
        expect(captureException).toHaveBeenCalledTimes(1);
        expect(captureException).toHaveBeenCalledWith({
          component: 'RunnerCreateForm',
          error: new Error(I18N_CREATE_ERROR),
        });
      });
    });
  });
});
