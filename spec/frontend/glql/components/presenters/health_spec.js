import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HealthPresenter from '~/glql/components/presenters/health.vue';

describe('HealthPresenter', () => {
  it.each`
    healthStatus        | badgeVariant | badgeLabel
    ${'onTrack'}        | ${'success'} | ${'On track'}
    ${'needsAttention'} | ${'warning'} | ${'Needs attention'}
    ${'atRisk'}         | ${'danger'}  | ${'At risk'}
  `(
    'for health status $healthStatus, it presents it as a badge with variant "$badgeVariant" and label "$badgeLabel"',
    ({ healthStatus, badgeVariant, badgeLabel }) => {
      const wrapper = shallowMountExtended(HealthPresenter, { propsData: { data: healthStatus } });
      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props('variant')).toBe(badgeVariant);
      expect(badge.text()).toBe(badgeLabel);
    },
  );
});
