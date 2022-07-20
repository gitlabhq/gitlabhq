import { shallowMount, mount } from '@vue/test-utils';
import { s__ } from '~/locale';
import RunnerStats from '~/runner/components/stat/runner_stats.vue';
import RunnerCount from '~/runner/components/stat/runner_count.vue';
import RunnerStatusStat from '~/runner/components/stat/runner_status_stat.vue';
import { INSTANCE_TYPE, STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '~/runner/constants';

describe('RunnerStats', () => {
  let wrapper;

  const findRunnerCountAt = (i) => wrapper.findAllComponents(RunnerCount).at(i);
  const findRunnerStatusStatAt = (i) => wrapper.findAllComponents(RunnerStatusStat).at(i);

  const createComponent = ({ props = {}, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(RunnerStats, {
      propsData: {
        scope: INSTANCE_TYPE,
        variables: {},
        ...props,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays all the stats', () => {
    const mockCounts = {
      [STATUS_ONLINE]: 3,
      [STATUS_OFFLINE]: 2,
      [STATUS_STALE]: 1,
    };

    createComponent({
      mountFn: mount,
      stubs: {
        RunnerCount: {
          props: ['variables'],
          render() {
            return this.$scopedSlots.default({
              count: mockCounts[this.variables.status],
            });
          },
        },
      },
    });

    const text = wrapper.text();
    expect(text).toMatch(`${s__('Runners|Online runners')} 3`);
    expect(text).toMatch(`${s__('Runners|Offline runners')} 2`);
    expect(text).toMatch(`${s__('Runners|Stale runners')} 1`);
  });

  it('Displays counts for filtered searches', () => {
    createComponent({ props: { variables: { paused: true } } });

    expect(findRunnerCountAt(0).props('variables').paused).toBe(true);
    expect(findRunnerCountAt(1).props('variables').paused).toBe(true);
    expect(findRunnerCountAt(2).props('variables').paused).toBe(true);
  });

  it('Skips overlapping statuses', () => {
    createComponent({ props: { variables: { status: STATUS_ONLINE } } });

    expect(findRunnerCountAt(0).props('skip')).toBe(false);
    expect(findRunnerCountAt(1).props('skip')).toBe(true);
    expect(findRunnerCountAt(2).props('skip')).toBe(true);
  });

  it.each`
    i    | status
    ${0} | ${STATUS_ONLINE}
    ${1} | ${STATUS_OFFLINE}
    ${2} | ${STATUS_STALE}
  `('Displays status $status at index $i', ({ i, status }) => {
    createComponent({ mountFn: mount });

    expect(findRunnerCountAt(i).props('variables').status).toBe(status);
    expect(findRunnerStatusStatAt(i).props('status')).toBe(status);
  });
});
