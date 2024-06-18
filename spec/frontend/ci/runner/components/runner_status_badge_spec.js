import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerStatusBadge from '~/ci/runner/components/runner_status_badge.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  I18N_STATUS_ONLINE,
  I18N_STATUS_NEVER_CONTACTED,
  I18N_STATUS_OFFLINE,
  I18N_STATUS_STALE,
  STATUS_ONLINE,
  STATUS_OFFLINE,
  STATUS_STALE,
  STATUS_NEVER_CONTACTED,
} from '~/ci/runner/constants';

describe('RunnerTypeBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const getTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  const createComponent = ({ props = {}, ...options } = {}) => {
    wrapper = shallowMount(RunnerStatusBadge, {
      propsData: {
        contactedAt: '2020-12-31T23:59:00Z',
        status: STATUS_ONLINE,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: false });
    jest.setSystemTime(new Date('2021-01-01T00:00:00Z'));
  });

  afterEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: true });
  });

  it('renders online state', () => {
    createComponent();

    expect(wrapper.text()).toBe(I18N_STATUS_ONLINE);
    expect(findBadge().props('variant')).toBe('success');
    expect(getTooltip().value).toBe('Last contact was 1 minute ago');
  });

  it('renders never contacted state', () => {
    createComponent({
      props: {
        contactedAt: null,
        status: STATUS_NEVER_CONTACTED,
      },
    });

    expect(wrapper.text()).toBe(I18N_STATUS_NEVER_CONTACTED);
    expect(findBadge().props('variant')).toBe('muted');
    expect(getTooltip().value).toBe('Runner has never contacted this instance');
  });

  it('renders offline state', () => {
    createComponent({
      props: {
        contactedAt: '2020-12-31T00:00:00Z',
        status: STATUS_OFFLINE,
      },
    });

    expect(wrapper.text()).toBe(I18N_STATUS_OFFLINE);
    expect(findBadge().props('variant')).toBe('muted');
    expect(getTooltip().value).toBe(
      "Runner hasn't contacted GitLab in more than 2 hours and last contact was 1 day ago",
    );
  });

  it('renders stale state', () => {
    createComponent({
      props: {
        contactedAt: '2020-01-01T00:00:00Z',
        status: STATUS_STALE,
      },
    });

    expect(wrapper.text()).toBe(I18N_STATUS_STALE);
    expect(findBadge().props('variant')).toBe('warning');
    expect(getTooltip().value).toBe(
      "Runner hasn't contacted GitLab in more than 1 week and last contact was 1 year ago",
    );
  });

  it('renders stale state with no contact time', () => {
    createComponent({
      props: {
        contactedAt: null,
        status: STATUS_STALE,
      },
    });

    expect(wrapper.text()).toBe(I18N_STATUS_STALE);
    expect(findBadge().props('variant')).toBe('warning');
    expect(getTooltip().value).toBe('Runner is older than 1 week and has never contacted GitLab');
  });

  describe('does not fail when data is missing', () => {
    it('contacted_at is missing', () => {
      createComponent({
        props: {
          contactedAt: null,
          status: STATUS_ONLINE,
        },
      });

      expect(wrapper.text()).toBe(I18N_STATUS_ONLINE);
      expect(getTooltip().value).toBe('Last contact was never');
    });

    it('status is missing', () => {
      createComponent({
        props: {
          status: null,
        },
      });

      expect(wrapper.text()).toBe('');
    });
  });

  describe('default timeout values are overridden', () => {
    it('shows a different offline timeout', () => {
      createComponent({
        props: {
          contactedAt: '2020-12-31T00:00:00Z',
          status: STATUS_OFFLINE,
        },
        provide: {
          onlineContactTimeoutSecs: 60,
        },
      });

      expect(getTooltip().value).toContain('1 minute');
    });

    it('shows a different stale timeout', () => {
      createComponent({
        props: {
          contactedAt: '2020-01-01T00:00:00Z',
          status: STATUS_STALE,
        },
        provide: {
          staleTimeoutSecs: 20 * 60,
        },
      });

      expect(getTooltip().value).toContain('20 minutes');
    });
  });
});
