import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerHeaderActions from '~/ci/runner/components/runner_header_actions.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerDetailsTabs from '~/ci/runner/components/runner_details_tabs.vue';
import RunnersJobs from '~/ci/runner/components/runner_jobs.vue';

import runnerQuery from '~/ci/runner/graphql/show/runner.query.graphql';
import GroupRunnerShowApp from '~/ci/runner/group_runner_show/group_runner_show_app.vue';
import { captureException } from '~/ci/runner/sentry_utils';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';

import { runnerData } from '../mock_data';

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockRunner = runnerData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;
const mockRunnerSha = mockRunner.shortSha;
const mockRunnersPath = '/groups/group1/-/runners';
const mockEditGroupRunnerPath = `/groups/group1/-/runners/${mockRunnerId}/edit`;

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('GroupRunnerShowApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
  const findRunnerHeaderActions = () => wrapper.findComponent(RunnerHeaderActions);
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
    wrapper = mountFn(GroupRunnerShowApp, {
      apolloProvider: createMockApollo([[runnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        editGroupRunnerPath: mockEditGroupRunnerPath,
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
      expect(findRunnerHeader().text()).toContain(`#${mockRunnerId} (${mockRunnerSha})`);
    });

    it('displays the runner buttons', () => {
      expect(findRunnerHeaderActions().props()).toEqual({
        runner: mockRunner,
        editPath: mockEditGroupRunnerPath,
      });
    });

    it('shows runner details', () => {
      expect(findRunnerDetailsTabs().props()).toEqual({
        runner: mockRunner,
        showAccessHelp: true,
      });
    });

    it('shows basic runner details', async () => {
      await createComponent({
        mountFn: mountExtended,
        stubs: {
          HelpPopover: {
            template: '<div/>',
          },
        },
      });

      const expected = `Description My Runner
                        Last contact Never contacted
                        Configuration Runs untagged jobs
                        Maximum job timeout None
                        Token expiry Never expires
                        Tags None`.replace(/\s+/g, ' ');

      expect(wrapper.text().replace(/\s+/g, ' ')).toContain(expected);
    });

    describe('when runner is deleted', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mountExtended,
        });
      });

      it('redirects to the runner list page', () => {
        findRunnerHeaderActions().vm.$emit('deleted', { message: 'Runner deleted' });

        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message: 'Runner deleted',
          variant: VARIANT_SUCCESS,
        });
        expect(visitUrl).toHaveBeenCalledWith(mockRunnersPath);
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
        component: 'GroupRunnerShowApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
