import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerStatusCell from '~/runner/components/cells/runner_status_cell.vue';
import { INSTANCE_TYPE, STATUS_ONLINE, STATUS_OFFLINE } from '~/runner/constants';

describe('RunnerTypeCell', () => {
  let wrapper;

  const findBadgeAt = (i) => wrapper.findAllComponents(GlBadge).at(i);

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
    expect(findBadgeAt(0).text()).toBe('online');
  });

  it('Displays offline status', () => {
    createComponent({
      runner: {
        status: STATUS_OFFLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText('offline');
    expect(findBadgeAt(0).text()).toBe('offline');
  });

  it('Displays paused status', () => {
    createComponent({
      runner: {
        active: false,
        status: STATUS_ONLINE,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText('online paused');

    expect(findBadgeAt(0).text()).toBe('online');
    expect(findBadgeAt(1).text()).toBe('paused');
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
