import { mount } from '@vue/test-utils';
import RunnerStatusCell from '~/runner/components/cells/runner_status_cell.vue';

import RunnerStatusBadge from '~/runner/components/runner_status_badge.vue';
import RunnerPausedBadge from '~/runner/components/runner_paused_badge.vue';
import { INSTANCE_TYPE, STATUS_ONLINE, STATUS_OFFLINE } from '~/runner/constants';

describe('RunnerStatusCell', () => {
  let wrapper;

  const findStatusBadge = () => wrapper.findComponent(RunnerStatusBadge);
  const findPausedBadge = () => wrapper.findComponent(RunnerPausedBadge);

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = mount(RunnerStatusCell, {
      propsData: {
        runner: {
          runnerType: INSTANCE_TYPE,
          active: true,
          status: STATUS_ONLINE,
          ...runner,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays online status', () => {
    createComponent();

    expect(wrapper.text()).toMatchInterpolatedText('online');
    expect(findStatusBadge().text()).toBe('online');
  });

  it('Displays offline status', () => {
    createComponent({
      runner: {
        status: STATUS_OFFLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText('offline');
    expect(findStatusBadge().text()).toBe('offline');
  });

  it('Displays paused status', () => {
    createComponent({
      runner: {
        active: false,
        status: STATUS_ONLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText('online paused');
    expect(findPausedBadge().text()).toBe('paused');
  });

  it('Is empty when data is missing', () => {
    createComponent({
      runner: {
        status: null,
      },
    });

    expect(wrapper.text()).toBe('');
  });
});
