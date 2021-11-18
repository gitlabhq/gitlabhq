import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerContactedStateBadge from '~/runner/components/runner_contacted_state_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_NOT_CONNECTED } from '~/runner/constants';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = shallowMount(RunnerContactedStateBadge, {
      propsData: {
        runner: {
          contactedAt: '2021-01-01T00:00:00Z',
          status: STATUS_ONLINE,
          ...runner,
        },
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    jest.useFakeTimers('modern');
  });

  afterEach(() => {
    jest.useFakeTimers('legacy');

    wrapper.destroy();
  });

  it('renders online state', () => {
    jest.setSystemTime(new Date('2021-01-01T00:01:00Z'));

    createComponent();

    expect(wrapper.text()).toBe('online');
    expect(findBadge().props('variant')).toBe('success');
    expect(getTooltip().value).toBe('Runner is online; last contact was 1 minute ago');
  });

  it('renders offline state', () => {
    jest.setSystemTime(new Date('2021-01-02T00:00:00Z'));

    createComponent({
      runner: {
        status: STATUS_OFFLINE,
      },
    });

    expect(wrapper.text()).toBe('offline');
    expect(findBadge().props('variant')).toBe('muted');
    expect(getTooltip().value).toBe(
      'No recent contact from this runner; last contact was 1 day ago',
    );
  });

  it('renders not connected state', () => {
    createComponent({
      runner: {
        contactedAt: null,
        status: STATUS_NOT_CONNECTED,
      },
    });

    expect(wrapper.text()).toBe('not connected');
    expect(findBadge().props('variant')).toBe('muted');
    expect(getTooltip().value).toMatch('This runner has never connected');
  });

  it('does not fail when data is missing', () => {
    createComponent({
      runner: {
        status: null,
      },
    });

    expect(wrapper.text()).toBe('');
  });
});
