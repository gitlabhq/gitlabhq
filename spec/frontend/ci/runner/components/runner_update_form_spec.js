import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { runnerToModel } from 'ee_else_ce/ci/runner/runner_update_form_utils';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import RunnerUpdateForm from '~/ci/runner/components/runner_update_form.vue';
import runnerUpdateMutation from '~/ci/runner/graphql/edit/runner_update.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import { INSTANCE_TYPE } from '~/ci/runner/constants';
import { runnerFormData } from '../mock_data';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockRunner = runnerFormData.data.runner;
const mockRunnerPath = '/admin/runners/1';

Vue.use(VueApollo);

describe('RunnerUpdateForm', () => {
  let wrapper;
  let runnerUpdateHandler;

  const findForm = () => wrapper.findComponent(GlForm);
  const findRunnerFormFields = () => wrapper.findComponent(RunnerFormFields);

  const findSubmit = () => wrapper.find('[type="submit"]');
  const findSubmitDisabledAttr = () => findSubmit().attributes('disabled');
  const findCancelBtn = () => wrapper.findByRole('link', { name: 'Cancel' });
  const submitForm = () => findForm().trigger('submit');
  const submitFormAndWait = () => submitForm().then(waitForPromises);

  const createComponent = ({ props } = {}) => {
    wrapper = mountExtended(RunnerUpdateForm, {
      propsData: {
        runner: null,
        runnerPath: mockRunnerPath,
        ...props,
      },
      apolloProvider: createMockApollo([[runnerUpdateMutation, runnerUpdateHandler]]),
    });
  };

  const expectToHaveSubmittedRunnerContaining = (submittedRunner) => {
    expect(runnerUpdateHandler).toHaveBeenCalledTimes(1);
    expect(runnerUpdateHandler).toHaveBeenCalledWith({
      input: expect.objectContaining(submittedRunner),
    });

    expect(saveAlertToLocalStorage).toHaveBeenCalledWith(
      expect.objectContaining({
        message: expect.any(String),
        variant: VARIANT_SUCCESS,
      }),
    );
    expect(visitUrl).toHaveBeenCalledWith(mockRunnerPath);
  };

  beforeEach(() => {
    runnerUpdateHandler = jest.fn().mockImplementation(({ input }) => {
      return Promise.resolve({
        data: {
          runnerUpdate: {
            runner: {
              ...mockRunner,
              ...input,
            },
            errors: [],
          },
        },
      });
    });
  });

  it('form has fields, submit and cancel buttons', () => {
    createComponent();

    expect(findRunnerFormFields().exists()).toBe(true);
    expect(findSubmit().exists()).toBe(true);
    expect(findCancelBtn().attributes('href')).toBe(mockRunnerPath);
  });

  describe('When data is being loaded', () => {
    beforeEach(() => {
      createComponent({ props: { loading: true } });
    });

    it('form has no runner', () => {
      expect(findRunnerFormFields().props('value')).toBe(null);
    });

    it('form cannot be submitted', () => {
      expect(findSubmit().props('loading')).toBe(true);
    });
  });

  describe('When runner has loaded', () => {
    beforeEach(async () => {
      createComponent({ props: { loading: true } });

      await wrapper.setProps({
        loading: false,
        runner: mockRunner,
      });
    });

    it('shows runner fields', () => {
      expect(findRunnerFormFields().props('value')).toEqual(runnerToModel(mockRunner));
      expect(findRunnerFormFields().props('runnerType')).toEqual(INSTANCE_TYPE);
    });

    it('form has not been submitted', () => {
      expect(runnerUpdateHandler).not.toHaveBeenCalled();
    });

    it('Form prevents multiple submissions', async () => {
      await submitForm();

      expect(findSubmitDisabledAttr()).toBe('disabled');
    });

    it('Updates runner with no changes', async () => {
      await submitFormAndWait();

      // Some read-only fields are not submitted
      const { __typename, shortSha, runnerType, createdAt, createdBy, status, ...submitted } =
        mockRunner;

      expectToHaveSubmittedRunnerContaining(submitted);
    });

    it('Updates runner with changes', async () => {
      findRunnerFormFields().vm.$emit(
        'input',
        runnerToModel({ ...mockRunner, description: 'A new description' }),
      );
      await submitFormAndWait();

      expectToHaveSubmittedRunnerContaining({ description: 'A new description' });
    });
  });

  describe('On error', () => {
    beforeEach(async () => {
      createComponent();

      await wrapper.setProps({
        loading: false,
        runner: mockRunner,
      });
    });

    it('On network error, error message is shown', async () => {
      const mockErrorMsg = 'Update error!';

      runnerUpdateHandler.mockRejectedValue(new Error(mockErrorMsg));

      await submitFormAndWait();

      expect(createAlert).toHaveBeenLastCalledWith({
        message: mockErrorMsg,
      });
      expect(captureException).toHaveBeenCalledWith({
        component: 'RunnerUpdateForm',
        error: new Error(mockErrorMsg),
      });
      expect(findSubmitDisabledAttr()).toBeUndefined();
    });

    it('On validation error, error message is shown and it is not sent to sentry', async () => {
      const mockErrorMsg = 'Invalid value!';

      runnerUpdateHandler.mockResolvedValue({
        data: {
          runnerUpdate: {
            runner: mockRunner,
            errors: [mockErrorMsg],
          },
        },
      });

      await submitFormAndWait();

      expect(createAlert).toHaveBeenLastCalledWith({
        message: mockErrorMsg,
      });
      expect(findSubmitDisabledAttr()).toBeUndefined();

      expect(captureException).not.toHaveBeenCalled();
      expect(saveAlertToLocalStorage).not.toHaveBeenCalled();
      expect(visitUrl).not.toHaveBeenCalled();
    });
  });
});
