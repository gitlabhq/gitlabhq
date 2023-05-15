import Vue, { nextTick } from 'vue';
import { GlForm, GlSkeletonLoader } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import RunnerUpdateForm from '~/ci/runner/components/runner_update_form.vue';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  ACCESS_LEVEL_REF_PROTECTED,
  ACCESS_LEVEL_NOT_PROTECTED,
} from '~/ci/runner/constants';
import runnerUpdateMutation from '~/ci/runner/graphql/edit/runner_update.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import { runnerFormData } from '../mock_data';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility');

const mockRunner = runnerFormData.data.runner;
const mockRunnerPath = '/admin/runners/1';

Vue.use(VueApollo);

describe('RunnerUpdateForm', () => {
  let wrapper;
  let runnerUpdateHandler;

  const findForm = () => wrapper.findComponent(GlForm);
  const findPausedCheckbox = () => wrapper.findByTestId('runner-field-paused');
  const findProtectedCheckbox = () => wrapper.findByTestId('runner-field-protected');
  const findRunUntaggedCheckbox = () => wrapper.findByTestId('runner-field-run-untagged');
  const findLockedCheckbox = () => wrapper.findByTestId('runner-field-locked');
  const findFields = () => wrapper.findAll('[data-testid^="runner-field"');

  const findDescriptionInput = () => wrapper.findByTestId('runner-field-description').find('input');
  const findMaxJobTimeoutInput = () =>
    wrapper.findByTestId('runner-field-max-timeout').find('input');
  const findTagsInput = () => wrapper.findByTestId('runner-field-tags').find('input');

  const findSubmit = () => wrapper.find('[type="submit"]');
  const findSubmitDisabledAttr = () => findSubmit().attributes('disabled');
  const findCancelBtn = () => wrapper.findByRole('link', { name: __('Cancel') });
  const submitForm = () => findForm().trigger('submit');
  const submitFormAndWait = () => submitForm().then(waitForPromises);

  const getFieldsModel = () => ({
    active: !findPausedCheckbox().element.checked,
    accessLevel: findProtectedCheckbox().element.checked
      ? ACCESS_LEVEL_REF_PROTECTED
      : ACCESS_LEVEL_NOT_PROTECTED,
    runUntagged: findRunUntaggedCheckbox().element.checked,
    locked: findLockedCheckbox().element?.checked || false,
    maximumTimeout: findMaxJobTimeoutInput().element.value || null,
    tagList: findTagsInput().element.value.split(',').filter(Boolean),
  });

  const createComponent = ({ props } = {}) => {
    wrapper = mountExtended(RunnerUpdateForm, {
      propsData: {
        runner: mockRunner,
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
    expect(redirectTo).toHaveBeenCalledWith(mockRunnerPath); // eslint-disable-line import/no-deprecated
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

    createComponent();
  });

  it('Form has a submit button', () => {
    expect(findSubmit().exists()).toBe(true);
  });

  it('Form fields match data', () => {
    expect(mockRunner).toMatchObject(getFieldsModel());
  });

  it('Form shows a cancel button', () => {
    expect(runnerUpdateHandler).not.toHaveBeenCalled();
    expect(findCancelBtn().attributes('href')).toBe(mockRunnerPath);
  });

  it('Form prevent multiple submissions', async () => {
    await submitForm();

    expect(findSubmitDisabledAttr()).toBe('disabled');
  });

  it('Updates runner with no changes', async () => {
    await submitFormAndWait();

    // Some read-only fields are not submitted
    const { __typename, shortSha, runnerType, createdAt, status, ...submitted } = mockRunner;

    expectToHaveSubmittedRunnerContaining(submitted);
  });

  describe('When data is being loaded', () => {
    beforeEach(() => {
      createComponent({ props: { loading: true } });
    });

    it('Form skeleton is shown', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
      expect(findFields()).toHaveLength(0);
    });

    it('Form cannot be submitted', () => {
      expect(findSubmit().props('loading')).toBe(true);
    });

    it('Form is updated when data loads', async () => {
      wrapper.setProps({
        loading: false,
      });

      await nextTick();

      expect(findFields()).not.toHaveLength(0);
      expect(mockRunner).toMatchObject(getFieldsModel());
    });
  });

  it.each`
    runnerType       | exists   | outcome
    ${INSTANCE_TYPE} | ${false} | ${'hidden'}
    ${GROUP_TYPE}    | ${false} | ${'hidden'}
    ${PROJECT_TYPE}  | ${true}  | ${'shown'}
  `(`When runner is $runnerType, locked field is $outcome`, ({ runnerType, exists }) => {
    const runner = { ...mockRunner, runnerType };
    createComponent({ props: { runner } });

    expect(findLockedCheckbox().exists()).toBe(exists);
  });

  describe('On submit, runner gets updated', () => {
    it.each`
      test                      | initialValue                                   | findCheckbox               | checked  | submitted
      ${'pauses'}               | ${{ active: true }}                            | ${findPausedCheckbox}      | ${true}  | ${{ active: false }}
      ${'activates'}            | ${{ active: false }}                           | ${findPausedCheckbox}      | ${false} | ${{ active: true }}
      ${'unprotects'}           | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED }} | ${findProtectedCheckbox}   | ${true}  | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED }}
      ${'protects'}             | ${{ accessLevel: ACCESS_LEVEL_REF_PROTECTED }} | ${findProtectedCheckbox}   | ${false} | ${{ accessLevel: ACCESS_LEVEL_NOT_PROTECTED }}
      ${'"runs untagged jobs"'} | ${{ runUntagged: true }}                       | ${findRunUntaggedCheckbox} | ${false} | ${{ runUntagged: false }}
      ${'"runs tagged jobs"'}   | ${{ runUntagged: false }}                      | ${findRunUntaggedCheckbox} | ${true}  | ${{ runUntagged: true }}
      ${'locks'}                | ${{ runnerType: PROJECT_TYPE, locked: true }}  | ${findLockedCheckbox}      | ${false} | ${{ locked: false }}
      ${'unlocks'}              | ${{ runnerType: PROJECT_TYPE, locked: false }} | ${findLockedCheckbox}      | ${true}  | ${{ locked: true }}
    `('Checkbox $test runner', async ({ initialValue, findCheckbox, checked, submitted }) => {
      const runner = { ...mockRunner, ...initialValue };
      createComponent({ props: { runner } });

      await findCheckbox().setChecked(checked);
      await submitFormAndWait();

      expectToHaveSubmittedRunnerContaining({
        id: runner.id,
        ...submitted,
      });
    });

    it.each`
      test             | initialValue                  | findInput                 | value           | submitted
      ${'description'} | ${{ description: 'Desc. 1' }} | ${findDescriptionInput}   | ${'Desc. 2'}    | ${{ description: 'Desc. 2' }}
      ${'max timeout'} | ${{ maximumTimeout: 36000 }}  | ${findMaxJobTimeoutInput} | ${'40000'}      | ${{ maximumTimeout: 40000 }}
      ${'tags'}        | ${{ tagList: ['tag1'] }}      | ${findTagsInput}          | ${'tag2, tag3'} | ${{ tagList: ['tag2', 'tag3'] }}
    `("Field updates runner's $test", async ({ initialValue, findInput, value, submitted }) => {
      const runner = { ...mockRunner, ...initialValue };
      createComponent({ props: { runner } });

      await findInput().setValue(value);
      await submitFormAndWait();

      expectToHaveSubmittedRunnerContaining({
        id: runner.id,
        ...submitted,
      });
    });

    it.each`
      value                  | submitted
      ${''}                  | ${{ tagList: [] }}
      ${'tag1, tag2'}        | ${{ tagList: ['tag1', 'tag2'] }}
      ${'with spaces'}       | ${{ tagList: ['with spaces'] }}
      ${'more ,,,,, commas'} | ${{ tagList: ['more', 'commas'] }}
    `('Field updates runner\'s tags for "$value"', async ({ value, submitted }) => {
      const runner = { ...mockRunner, tagList: ['tag1'] };
      createComponent({ props: { runner } });

      await findTagsInput().setValue(value);
      await submitFormAndWait();

      expectToHaveSubmittedRunnerContaining({
        id: runner.id,
        ...submitted,
      });
    });
  });

  describe('On error', () => {
    beforeEach(() => {
      createComponent();
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
      expect(redirectTo).not.toHaveBeenCalled(); // eslint-disable-line import/no-deprecated
    });
  });
});
