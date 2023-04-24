import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

import ProjectRunnerRunnerApp from '~/ci/runner/project_new_runner/project_new_runner_app.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import { PROJECT_TYPE, DEFAULT_PLATFORM } from '~/ci/runner/constants';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { runnerCreateResult, mockRegistrationToken } from '../mock_data';

const mockProjectId = 'gid://gitlab/Project/72';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

describe('ProjectRunnerRunnerApp', () => {
  let wrapper;

  const findRunnerPlatformsRadioGroup = () => wrapper.findComponent(RunnerPlatformsRadioGroup);
  const findRunnerCreateForm = () => wrapper.findComponent(RunnerCreateForm);

  const createComponent = () => {
    wrapper = shallowMountExtended(ProjectRunnerRunnerApp, {
      propsData: {
        projectId: mockProjectId,
        legacyRegistrationToken: mockRegistrationToken,
      },
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
        runnerType: PROJECT_TYPE,
        projectId: mockProjectId,
        groupId: null,
      });
    });

    describe('When a runner is saved', () => {
      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('shows an alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: s__('Runners|Runner created.'),
          variant: VARIANT_SUCCESS,
        });
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
