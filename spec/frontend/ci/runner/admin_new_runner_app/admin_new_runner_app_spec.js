import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

import AdminNewRunnerApp from '~/ci/runner/admin_new_runner/admin_new_runner_app.vue';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import {
  PARAM_KEY_PLATFORM,
  INSTANCE_TYPE,
  DEFAULT_PLATFORM,
  WINDOWS_PLATFORM,
} from '~/ci/runner/constants';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { runnerCreateResult } from '../mock_data';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

describe('AdminNewRunnerApp', () => {
  let wrapper;

  const findRunnerPlatformsRadioGroup = () => wrapper.findComponent(RunnerPlatformsRadioGroup);
  const findRunnerCreateForm = () => wrapper.findComponent(RunnerCreateForm);

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminNewRunnerApp, {
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Platform', () => {
    it('shows the platforms radio group', () => {
      expect(findRunnerPlatformsRadioGroup().props('value')).toBe(DEFAULT_PLATFORM);
    });
  });

  describe('Runner form', () => {
    it('shows the runner create form for an instance runner', () => {
      expect(findRunnerCreateForm().props()).toEqual({
        runnerType: INSTANCE_TYPE,
        groupId: null,
        projectId: null,
      });
    });

    describe('When a runner is saved', () => {
      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('pushes an alert to be shown after redirection', () => {
        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message: s__('Runners|Runner created.'),
          variant: VARIANT_SUCCESS,
        });
      });

      it('redirects to the registration page', () => {
        const url = `${mockCreatedRunner.ephemeralRegisterUrl}?${PARAM_KEY_PLATFORM}=${DEFAULT_PLATFORM}`;

        expect(visitUrl).toHaveBeenCalledWith(url);
      });
    });

    describe('When another platform is selected and a runner is saved', () => {
      beforeEach(() => {
        findRunnerPlatformsRadioGroup().vm.$emit('input', WINDOWS_PLATFORM);
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('redirects to the registration page with the platform', () => {
        const url = `${mockCreatedRunner.ephemeralRegisterUrl}?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`;

        expect(visitUrl).toHaveBeenCalledWith(url);
      });
    });

    describe('When runner fails to save', () => {
      const ERROR_MSG = 'Cannot save!';

      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('error', new Error(ERROR_MSG));
      });

      it('shows an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({ message: ERROR_MSG });
      });
    });
  });
});
