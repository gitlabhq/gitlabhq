import { mount } from '@vue/test-utils';
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
} from '~/ci/runner/constants';

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
        active: false,
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
});
