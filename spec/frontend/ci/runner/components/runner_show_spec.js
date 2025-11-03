import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import runnerQuery from '~/ci/runner/graphql/show/runner.query.graphql';

import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert';
import { captureException } from '~/ci/runner/sentry_utils';

import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerHeaderActions from '~/ci/runner/components/runner_header_actions.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';

import RunnerShow from '~/ci/runner/components/runner_show.vue';

import { runnerData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/local_storage_alert');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

const mockRunnerId = '1';
const mockRunnersPath = '/runners';
const mockEditPath = '/runners/1/edit';
const mockRunner = runnerData.data.runner;

describe('RunnerShow', () => {
  let wrapper;
  let mockApollo;
  let runnerQueryHandler;

  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerHeaderActions = () => wrapper.findComponent(RunnerHeaderActions);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);

  const createComponent = ({ props = {} } = {}) => {
    mockApollo = createMockApollo([[runnerQuery, runnerQueryHandler]]);

    wrapper = shallowMountExtended(RunnerShow, {
      apolloProvider: mockApollo,
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        editPath: mockEditPath,
        ...props,
      },
    });

    return waitForPromises();
  };

  beforeEach(() => {
    runnerQueryHandler = jest.fn().mockResolvedValue({
      data: {
        runner: mockRunner,
      },
    });
  });

  it('fetches runner data with the correct ID', async () => {
    await createComponent();

    expect(runnerQueryHandler).toHaveBeenCalledWith({
      id: expect.stringContaining(`/${mockRunnerId}`),
    });
  });

  it('passes the correct props to RunnerHeader', async () => {
    await createComponent();

    expect(findRunnerHeader().props('runner')).toEqual(mockRunner);
    expect(findRunnerHeaderActions().props()).toEqual({
      runner: mockRunner,
      editPath: mockEditPath,
    });
  });

  it('redirects to runners path when runner is deleted', async () => {
    await createComponent();

    const message = 'Runner deleted successfully';

    findRunnerHeaderActions().vm.$emit('deleted', { message });

    expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
      message,
      variant: 'success',
    });
    expect(visitUrl).toHaveBeenCalledWith(mockRunnersPath);
  });

  it('shows an alert when fetching runner data fails', async () => {
    const error = new Error('Network error');
    runnerQueryHandler.mockRejectedValue(error);

    await createComponent();

    expect(findRunnerHeader().exists()).toEqual(false);
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while fetching runner data.',
    });
    expect(captureException).toHaveBeenCalledWith({
      error,
      component: 'RunnerShow',
    });
  });

  it('does not redirect when runnersPath is not provided', async () => {
    await createComponent({
      props: {
        runnersPath: '',
      },
    });

    const message = 'Runner deleted successfully';
    wrapper.findComponent(RunnerHeaderActions).vm.$emit('deleted', { message });

    expect(saveAlertToLocalStorage).not.toHaveBeenCalled();
    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('shows basic runner details', async () => {
    await createComponent();

    expect(findRunnerDetails().props('runner')).toEqual(mockRunner);
  });
});
