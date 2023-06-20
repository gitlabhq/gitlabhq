import { shallowMount } from '@vue/test-utils';
import RunnerStatusCell from '~/ci/runner/components/cells/runner_status_cell.vue';

import RunnerStatusBadge from '~/ci/runner/components/runner_status_badge.vue';
import RunnerPausedBadge from '~/ci/runner/components/runner_paused_badge.vue';
import {
  I18N_PAUSED,
  I18N_STATUS_ONLINE,
  I18N_STATUS_OFFLINE,
  INSTANCE_TYPE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  JOB_STATUS_IDLE,
} from '~/ci/runner/constants';

describe('RunnerStatusCell', () => {
  let wrapper;

  const findStatusBadge = () => wrapper.findComponent(RunnerStatusBadge);
  const findPausedBadge = () => wrapper.findComponent(RunnerPausedBadge);

  const createComponent = ({ runner = {}, ...options } = {}) => {
    wrapper = shallowMount(RunnerStatusCell, {
      propsData: {
        runner: {
          runnerType: INSTANCE_TYPE,
          paused: false,
          status: STATUS_ONLINE,
          jobExecutionStatus: JOB_STATUS_IDLE,
          ...runner,
        },
      },
      stubs: {
        RunnerStatusBadge,
        RunnerPausedBadge,
      },
      ...options,
    });
  };

  it('Displays online status', () => {
    createComponent();

    expect(wrapper.text()).toContain(I18N_STATUS_ONLINE);
    expect(findStatusBadge().text()).toBe(I18N_STATUS_ONLINE);
  });

  it('Displays offline status', () => {
    createComponent({
      runner: {
        status: STATUS_OFFLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText(I18N_STATUS_OFFLINE);
    expect(findStatusBadge().text()).toBe(I18N_STATUS_OFFLINE);
  });

  it('Displays paused status', () => {
    createComponent({
      runner: {
        paused: true,
        status: STATUS_ONLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText(`${I18N_STATUS_ONLINE} ${I18N_PAUSED}`);
    expect(findPausedBadge().text()).toBe(I18N_PAUSED);
  });

  it('Is empty when data is missing', () => {
    createComponent({
      runner: {
        status: null,
      },
    });

    expect(wrapper.text()).toBe('');
  });

  it('Displays "runner-job-status-badge" slot', () => {
    createComponent({
      scopedSlots: {
        'runner-job-status-badge': ({ runner }) => `Job status ${runner.jobExecutionStatus}`,
      },
    });

    expect(wrapper.text()).toContain(`Job status ${JOB_STATUS_IDLE}`);
  });
});
