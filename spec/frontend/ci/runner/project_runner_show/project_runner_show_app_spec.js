import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerDetailsTabs from '~/ci/runner/components/runner_details_tabs.vue';
import RunnersJobs from '~/ci/runner/components/runner_jobs.vue';

import runnerQuery from '~/ci/runner/graphql/show/runner.query.graphql';
import ProjectRunnerShowApp from '~/ci/runner/project_runner_show/project_runner_show_app.vue';
import { captureException } from '~/ci/runner/sentry_utils';

import { runnerData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const mockRunner = runnerData.data.runner;
const mockRunnerGraphqlId = mockRunner.id;
const mockRunnerId = `${getIdFromGraphQLId(mockRunnerGraphqlId)}`;
const mockRunnerSha = mockRunner.shortSha;

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('AdminRunnerShowApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
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
    wrapper = mountFn(ProjectRunnerShowApp, {
      apolloProvider: createMockApollo([[runnerQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
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

    it('shows runner details', () => {
      expect(findRunnerDetailsTabs().props('runner')).toEqual(mockRunner);
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
        component: 'ProjectRunnerShowApp',
      });
    });

    it('error is shown to the user', () => {
      expect(createAlert).toHaveBeenCalled();
    });
  });
});
