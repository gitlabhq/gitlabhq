import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

describe('CI Badge Link Component', () => {
  let wrapper;

  const statuses = {
    canceled: {
      text: 'canceled',
      label: 'canceled',
      group: 'canceled',
      icon: 'status_canceled',
      details_path: 'status/canceled',
    },
    created: {
      text: 'created',
      label: 'created',
      group: 'created',
      icon: 'status_created',
      details_path: 'status/created',
    },
    failed: {
      text: 'failed',
      label: 'failed',
      group: 'failed',
      icon: 'status_failed',
      details_path: 'status/failed',
    },
    manual: {
      text: 'manual',
      label: 'manual action',
      group: 'manual',
      icon: 'status_manual',
      details_path: 'status/manual',
    },
    pending: {
      text: 'pending',
      label: 'pending',
      group: 'pending',
      icon: 'status_pending',
      details_path: 'status/pending',
    },
    preparing: {
      text: 'preparing',
      label: 'preparing',
      group: 'preparing',
      icon: 'status_preparing',
      details_path: 'status/preparing',
    },
    running: {
      text: 'running',
      label: 'running',
      group: 'running',
      icon: 'status_running',
      details_path: 'status/running',
    },
    scheduled: {
      text: 'scheduled',
      label: 'scheduled',
      group: 'scheduled',
      icon: 'status_scheduled',
      details_path: 'status/scheduled',
    },
    skipped: {
      text: 'skipped',
      label: 'skipped',
      group: 'skipped',
      icon: 'status_skipped',
      details_path: 'status/skipped',
    },
    success_warining: {
      text: 'warning',
      label: 'passed with warnings',
      group: 'success-with-warnings',
      icon: 'status_warning',
      details_path: 'status/warning',
    },
    success: {
      text: 'passed',
      label: 'passed',
      group: 'passed',
      icon: 'status_success',
      details_path: 'status/passed',
    },
  };

  const findIcon = () => wrapper.findComponent(CiIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findBadgeText = () => wrapper.find('[data-testid="ci-badge-text"');

  const createComponent = (propsData) => {
    wrapper = shallowMount(CiBadgeLink, { propsData });
  };

  it.each(Object.keys(statuses))('should render badge for status: %s', (status) => {
    createComponent({ status: statuses[status] });

    expect(wrapper.attributes('href')).toBe(statuses[status].details_path);
    expect(wrapper.text()).toBe(statuses[status].text);
    expect(findBadge().props('size')).toBe('md');
    expect(findIcon().exists()).toBe(true);
  });

  it.each`
    status                       | textColor               | variant
    ${statuses.success}          | ${'gl-text-green-700'}  | ${'success'}
    ${statuses.success_warining} | ${'gl-text-orange-700'} | ${'warning'}
    ${statuses.failed}           | ${'gl-text-red-700'}    | ${'danger'}
    ${statuses.running}          | ${'gl-text-blue-700'}   | ${'info'}
    ${statuses.pending}          | ${'gl-text-orange-700'} | ${'warning'}
    ${statuses.preparing}        | ${'gl-text-gray-600'}   | ${'muted'}
    ${statuses.canceled}         | ${'gl-text-gray-700'}   | ${'neutral'}
    ${statuses.scheduled}        | ${'gl-text-gray-600'}   | ${'muted'}
    ${statuses.skipped}          | ${'gl-text-gray-600'}   | ${'muted'}
    ${statuses.manual}           | ${'gl-text-gray-700'}   | ${'neutral'}
    ${statuses.created}          | ${'gl-text-gray-600'}   | ${'muted'}
  `(
    'should contain correct badge class and variant for status: $status.text',
    ({ status, textColor, variant }) => {
      createComponent({ status });

      expect(findBadgeText().classes()).toContain(textColor);
      expect(findBadge().props('variant')).toBe(variant);
    },
  );

  it('should not render label', () => {
    createComponent({ status: statuses.canceled, showText: false });

    expect(wrapper.text()).toBe('');
  });

  it('should emit ciStatusBadgeClick event', () => {
    createComponent({ status: statuses.success });

    findBadge().vm.$emit('click');

    expect(wrapper.emitted('ciStatusBadgeClick')).toEqual([[]]);
  });

  it('should render dynamic badge size', () => {
    createComponent({ status: statuses.success, badgeSize: 'lg' });

    expect(findBadge().props('size')).toBe('lg');
  });
});
