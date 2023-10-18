import Vue from 'vue';
import { GlTab, GlTabs } from '@gitlab/ui';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { JOBS_ROUTE_PATH, I18N_DETAILS, I18N_JOBS } from '~/ci/runner/constants';

import RunnerDetailsTabs from '~/ci/runner/components/runner_details_tabs.vue';
import RunnerDetails from '~/ci/runner/components/runner_details.vue';
import RunnerJobs from '~/ci/runner/components/runner_jobs.vue';

import { runnerData } from '../mock_data';

// Vue Test Utils `stubs` option does not stub components mounted
// in <router-view>. Use mocking instead:
jest.mock('~/ci/runner/components/runner_jobs.vue', () => {
  const { props } = jest.requireActual('~/ci/runner/components/runner_jobs.vue').default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ci/runner/components/runner_managers_detail.vue', () => {
  const { props } = jest.requireActual('~/ci/runner/components/runner_managers_detail.vue').default;
  return {
    props,
    render() {},
  };
});

const mockRunner = runnerData.data.runner;

Vue.use(VueApollo);
Vue.use(VueRouter);

describe('RunnerDetailsTabs', () => {
  let wrapper;
  let routerPush;

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findRunnerDetails = () => wrapper.findComponent(RunnerDetails);
  const findRunnerJobs = () => wrapper.findComponent(RunnerJobs);
  const findJobCountBadge = () => wrapper.findByTestId('job-count-badge');

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerDetailsTabs, {
      propsData: {
        runner: mockRunner,
        ...props,
      },
      ...options,
    });

    routerPush = jest.spyOn(wrapper.vm.$router, 'push');

    return waitForPromises();
  };

  it('shows basic runner details', async () => {
    await createComponent({ mountFn: mountExtended });

    expect(findRunnerDetails().props('runner')).toBe(mockRunner);
    expect(findRunnerJobs().exists()).toBe(false);
  });

  it('shows runner jobs', async () => {
    createComponent({ mountFn: mountExtended });
    await wrapper.vm.$router.push({ path: JOBS_ROUTE_PATH });

    expect(findRunnerDetails().exists()).toBe(false);
    expect(findRunnerJobs().props('runner')).toBe(mockRunner);
  });

  it.each`
    jobCount | badgeText
    ${null}  | ${null}
    ${1}     | ${'1'}
    ${1000}  | ${'1,000'}
    ${1001}  | ${'1,000+'}
  `('shows runner jobs count', async ({ jobCount, badgeText }) => {
    await createComponent({
      stubs: {
        GlTab,
      },
      props: {
        runner: {
          ...mockRunner,
          jobCount,
        },
      },
    });

    if (!badgeText) {
      expect(findJobCountBadge().exists()).toBe(false);
    } else {
      expect(findJobCountBadge().text()).toBe(badgeText);
    }
  });

  it.each(['#/', '#/unknown-tab'])('shows details when location hash is `%s`', async (path) => {
    createComponent({ mountFn: mountExtended });
    await wrapper.vm.$router.push({ path });

    expect(findTabs().props('value')).toBe(0);
    expect(findRunnerDetails().exists()).toBe(true);
    expect(findRunnerJobs().exists()).toBe(false);
  });

  describe.each`
    location       | tab             | navigatedTo
    ${'#/details'} | ${I18N_DETAILS} | ${[]}
    ${'#/details'} | ${I18N_JOBS}    | ${[[{ name: 'jobs' }]]}
    ${'#/jobs'}    | ${I18N_JOBS}    | ${[]}
    ${'#/jobs'}    | ${I18N_DETAILS} | ${[[{ name: 'details' }]]}
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
