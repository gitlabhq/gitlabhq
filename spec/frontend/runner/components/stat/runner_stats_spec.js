import { shallowMount, mount } from '@vue/test-utils';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerStatusStat from '~/runner/components/stat/runner_status_stat.vue';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '~/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerStatusStatAt = (i) => wrapper.findAllComponents(RunnerStatusStat).at(i);

  const createComponent = ({ props = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerStats, {
      propsData: {
        onlineRunnersCount: 3,
        offlineRunnersCount: 2,
        staleRunnersCount: 1,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays all the stats', () => {
    createComponent({ mountFn: mount });

    const stats = wrapper.text();

    expect(stats).toMatch('Online runners 3');
    expect(stats).toMatch('Offline runners 2');
    expect(stats).toMatch('Stale runners 1');
  });

  it.each`
    i    | status
    ${0} | ${STATUS_ONLINE}
    ${1} | ${STATUS_OFFLINE}
    ${2} | ${STATUS_STALE}
  `('Displays status types at index $i', ({ i, status }) => {
    createComponent();

    expect(findRunnerStatusStatAt(i).props('status')).toBe(status);
  });
});
