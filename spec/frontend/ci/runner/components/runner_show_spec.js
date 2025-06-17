import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';

import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import runnerQuery from '~/ci/runner/graphql/show/runner.query.graphql';

import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { visitUrl } from '~/lib/utils/url_utility';

import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import { captureException } from '~/ci/runner/sentry_utils';
import { JOBS_ROUTE_PATH } from '~/ci/runner/constants';

import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerHeaderActions from '~/ci/runner/components/runner_header_actions.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerJobs from '~/ci/runner/components/runner_jobs.vue';

import RunnerShow from '~/ci/runner/components/runner_show.vue';

import { runnerData } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueRouter);
Vue.use(VueApollo);

const mockRunnerId = '1';
const mockRunnersPath = '/runners';
const mockEditPath = '/runners/1/edit';
const mockRunner = runnerData.data.runner;

describe('RunnerShow', () => {
  let wrapper;
  let mockApollo;
  let routerPush;
  let runnerQueryHandler;

  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
  const findRunnerJobs = () => wrapper.findComponent(RunnerJobs);
  const findJobCountBadge = () => wrapper.findByTestId('job-count-badge');
  const findRunnerHeader = () => wrapper.findComponent(RunnerHeader);
  const findRunnerHeaderActions = () => wrapper.findComponent(RunnerHeaderActions);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    mockApollo = createMockApollo([[runnerQuery, runnerQueryHandler]]);

    wrapper = mountFn(RunnerShow, {
      apolloProvider: mockApollo,
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        editPath: mockEditPath,
        ...props,
      },
    });

    routerPush = jest.spyOn(wrapper.vm.$router, 'push');

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

  describe('access help', () => {
    it('show popover when showAccessHelp is true', async () => {
      await createComponent({
        props: {
          showAccessHelp: true,
        },
      });

      expect(findHelpPopover().exists()).toBe(true);
    });

    it('hides popover when showAccessHelp is not added', async () => {
      await createComponent();

      expect(findHelpPopover().exists()).toBe(false);
    });
  });

  it('shows basic runner details', async () => {
    await createComponent({ mountFn: mountExtended });

    expect(findRunnerDetails().props('runner')).toEqual(mockRunner);
    expect(findRunnerJobs().exists()).toBe(false);
  });

  it('shows runner jobs', async () => {
    createComponent({ mountFn: mountExtended });
    await wrapper.vm.$router.push({ path: JOBS_ROUTE_PATH });

    expect(findRunnerDetails().exists()).toBe(false);
    expect(findRunnerJobs().props('runnerId')).toBe(mockRunnerId);
  });

  it.each`
    jobCount | badgeText
    ${null}  | ${null}
    ${1}     | ${'1'}
    ${1000}  | ${'1,000'}
    ${1001}  | ${'1,000+'}
  `('shows runner jobs count', async ({ jobCount, badgeText }) => {
    runnerQueryHandler = jest.fn().mockResolvedValue({
      data: {
        runner: { ...mockRunner, jobCount },
      },
    });

    await createComponent();

    if (!badgeText) {
      expect(findJobCountBadge().exists()).toBe(false);
    } else {
      expect(findJobCountBadge().text()).toBe(badgeText);
    }
  });

  it.each(['#/', '#/unknown-tab'])('shows details when location hash is `%s`', async (path) => {
    createComponent({ mountFn: mountExtended });
    await wrapper.vm.$router.push({ path });

    expect(findRunnerDetails().exists()).toBe(true);
    expect(findRunnerJobs().exists()).toBe(false);
  });

  describe.each`
    location       | tab          | navigatedTo
    ${'#/details'} | ${'Details'} | ${[]}
    ${'#/details'} | ${'Jobs'}    | ${[[{ name: 'jobs' }]]}
    ${'#/jobs'}    | ${'Jobs'}    | ${[]}
    ${'#/jobs'}    | ${'Details'} | ${[[{ name: 'details' }]]}
  `('When at $location', ({ location, tab, navigatedTo }) => {
    beforeEach(async () => {
      setWindowLocation(location);

      await createComponent({
        mountFn: mountExtended,
      });
    });

    it(`on click on ${tab}, navigates to ${JSON.stringify(navigatedTo)}`, () => {
      wrapper.findByText(tab).trigger('click');

      expect(routerPush.mock.calls).toEqual(navigatedTo);
    });
  });
});
