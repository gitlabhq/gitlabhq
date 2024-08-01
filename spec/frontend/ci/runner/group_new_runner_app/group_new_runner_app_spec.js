import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_SUCCESS } from '~/alert';

import GroupRunnerRunnerApp from '~/ci/runner/group_new_runner/group_new_runner_app.vue';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import { GROUP_TYPE } from '~/ci/runner/constants';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { runnerCreateResult } from '../mock_data';

const mockGroupId = 'gid://gitlab/Group/72';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

describe('GroupRunnerRunnerApp', () => {
  let wrapper;
  let trackingSpy;

  const findRunnerCreateForm = () => wrapper.findComponent(RunnerCreateForm);

  const createComponent = () => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    wrapper = shallowMountExtended(GroupRunnerRunnerApp, {
      propsData: {
        groupId: mockGroupId,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Runner form', () => {
    it('shows the runner create form for an instance runner', () => {
      expect(findRunnerCreateForm().props()).toEqual({
        runnerType: GROUP_TYPE,
        groupId: mockGroupId,
        projectId: null,
      });
    });

    describe('When a runner is saved', () => {
      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('pushes an alert to be shown after redirection', () => {
        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message: 'Runner created.',
          variant: VARIANT_SUCCESS,
        });
      });

      it('tracks that create runner button has been clicked', () => {
        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'click_create_group_runner_button',
          expect.any(Object),
        );
      });

      it('redirects to the registration page', () => {
        expect(visitUrl).toHaveBeenCalledWith(mockCreatedRunner.ephemeralRegisterUrl);
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
