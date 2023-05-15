import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerPauseButton from '~/ci/runner/components/runner_pause_button.vue';
import RunnerDeleteButton from '~/ci/runner/components/runner_delete_button.vue';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';
import RunnerDetailsTabs from '~/ci/runner/components/runner_details_tabs.vue';
import RunnersJobs from '~/ci/runner/components/runner_jobs.vue';

import runnerQuery from '~/ci/runner/graphql/show/runner.query.graphql';
import AdminRunnerShowApp from '~/ci/runner/admin_runner_show/admin_runner_show_app.vue';
import { captureException } from '~/ci/runner/sentry_utils';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';

import { runnerData } from '../mock_data';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility');

const mockRunner = runnerData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;
const mockRunnersPath = '/admin/runners';

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('AdminRunnerShowApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
  const findRunnerDeleteButton = () => wrapper.findComponent(RunnerDeleteButton);
  const findRunnerEditButton = () => wrapper.findComponent(RunnerEditButton);
  const findRunnerPauseButton = () => wrapper.findComponent(RunnerPauseButton);
  const findRunnerDetailsTabs = () => wrapper.findComponent(RunnerDetailsTabs);
  const findRunnersJobs = () => wrapper.findComponent(RunnersJobs);

  const mockRunnerQueryResult = (runner = {}) => {
    mockRunnerQuery = jest.fn().mockResolvedValue({
      data: {
        runner: { ...mockRunner, ...runner },
      },
    });
  };

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(AdminRunnerShowApp, {
      apolloProvider: createMockApollo([[runnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        ...props,
      },
      ...options,
    });

    return waitForPromises();
  };

  afterEach(() => {
    mockRunnerQuery.mockReset();
  });

  describe('When showing runner details', () => {
    beforeEach(async () => {
      mockRunnerQueryResult();

      await createComponent({ mountFn: mountExtended });
    });

    it('expect GraphQL ID to be requested', () => {
      expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunnerGraphqlId });
    });

    it('displays the runner header', () => {
      expect(findRunnerHeader().text()).toContain(`Runner #${mockRunnerId}`);
    });

    it('displays the runner edit and pause buttons', () => {
      expect(findRunnerEditButton().attributes('href')).toBe(mockRunner.editAdminUrl);
      expect(findRunnerPauseButton().exists()).toBe(true);
      expect(findRunnerDeleteButton().exists()).toBe(true);
    });

    it('shows runner details', () => {
      expect(findRunnerDetailsTabs().props('runner')).toEqual(mockRunner);
    });

    it('shows basic runner details', () => {
      const expected = `Description My Runner
                        Last contact Never contacted
                        Version 1.0.0
                        IP Address None
                        Executor None
                        Architecture None
                        Platform darwin
                        Configuration Runs untagged jobs
                        Maximum job timeout None
                        Token expiry
                        Runner authentication token expiration
                        Runner authentication tokens will expire based on a set interval.
                        They will automatically rotate once expired. Learn more Never expires
                        Tags None`.replace(/\s+/g, ' ');

      expect(wrapper.text().replace(/\s+/g, ' ')).toContain(expected);
    });

    describe('when runner cannot be updated', () => {
      beforeEach(async () => {
        mockRunnerQueryResult({
          userPermissions: {
            ...mockRunner.userPermissions,
            updateRunner: false,
          },
        });

        await createComponent({
          mountFn: mountExtended,
        });
      });

      it('does not display the runner edit and pause buttons', () => {
        expect(findRunnerEditButton().exists()).toBe(false);
        expect(findRunnerPauseButton().exists()).toBe(false);
      });

      it('displays delete button', () => {
        expect(findRunnerDeleteButton().exists()).toBe(true);
      });
    });

    describe('when runner cannot be deleted', () => {
      beforeEach(async () => {
        mockRunnerQueryResult({
          userPermissions: {
            ...mockRunner.userPermissions,
            deleteRunner: false,
          },
        });

        await createComponent({
          mountFn: mountExtended,
        });
      });

      it('does not display the delete button', () => {
        expect(findRunnerDeleteButton().exists()).toBe(false);
      });

      it('displays edit and pause buttons', () => {
        expect(findRunnerEditButton().exists()).toBe(true);
        expect(findRunnerPauseButton().exists()).toBe(true);
      });
    });

    describe('when runner is deleted', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
        });
      });

      it('redirects to the runner list page', () => {
        findRunnerDeleteButton().vm.$emit('deleted', { message: 'Runner deleted' });

        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message: 'Runner deleted',
          variant: VARIANT_SUCCESS,
        });
        expect(redirectTo).toHaveBeenCalledWith(mockRunnersPath); // eslint-disable-line import/no-deprecated
      });
    });

    describe('when runner does not have an edit url', () => {
      beforeEach(async () => {
        mockRunnerQueryResult({
          editAdminUrl: null,
        });

        await createComponent({
          mountFn: mountExtended,
        });
      });

      it('does not display the runner edit button', () => {
        expect(findRunnerEditButton().exists()).toBe(false);
        expect(findRunnerPauseButton().exists()).toBe(true);
      });
    });
  });

  describe('When loading', () => {
    it('does not show runner details', () => {
      mockRunnerQueryResult();

      createComponent();

      expect(findRunnerDetails().exists()).toBe(false);
    });

    it('does not show runner jobs', () => {
      mockRunnerQueryResult();

      createComponent();

      expect(findRunnersJobs().exists()).toBe(false);
    });
  });

  describe('When there is an error', () => {
    beforeEach(async () => {
      mockRunnerQuery = jest.fn().mockRejectedValueOnce(new Error('Error!'));
      await createComponent();
    });

    it('does not show runner details', () => {
      expect(findRunnerDetails().exists()).toBe(false);
    });

    it('error is reported to sentry', () => {
      expect(captureException).toHaveBeenCalledWith({
        error: new Error('Error!'),
        component: 'AdminRunnerShowApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
