import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import runnerJobCountQuery from '~/ci/runner/graphql/list/runner_job_count.query.graphql';

import RunnerJobCount from '~/ci/runner/components/runner_job_count.vue';

import { runnerJobCountData } from '../mock_data';

const mockRunner = runnerJobCountData.data.runner;

Vue.use(VueApollo);

describe('RunnerJobCount', () => {
  let wrapper;
  let runnerJobCountHandler;

  const createComponent = ({ props = {}, ...options } = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerJobCount, {
      apolloProvider: createMockApollo([[runnerJobCountQuery, runnerJobCountHandler]]),
      propsData: {
        runner: mockRunner,
        ...props,
      },
      ...options,
    });
  };

  beforeEach(() => {
    runnerJobCountHandler = jest.fn().mockReturnValue(new Promise(() => {}));
  });

  it('Loads data while it displays empty content', () => {
    createComponent();

    expect(runnerJobCountHandler).toHaveBeenCalledWith({ id: mockRunner.id });
    expect(wrapper.text()).toBe('-');
  });

  it('Sets a batch key for the "jobCount" query', () => {
    createComponent();

    expect(wrapper.vm.$apollo.queries.jobCount.options.context.batchKey).toBe('RunnerJobCount');
  });

  it('Displays job count', async () => {
    runnerJobCountHandler.mockResolvedValue(runnerJobCountData);

    createComponent();

    await waitForPromises();

    expect(wrapper.text()).toBe('999');
  });

  it('Displays formatted job count', async () => {
    runnerJobCountHandler.mockResolvedValue({
      data: {
        runner: {
          ...mockRunner,
          jobCount: 1001,
        },
      },
    });

    createComponent();

    await waitForPromises();

    expect(wrapper.text()).toBe('1,000+');
  });
});
