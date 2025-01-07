import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatePresenter from '~/glql/components/presenters/state.vue';

describe('StatePresenter', () => {
  it.each`
    issueState  | badgeVariant | badgeLabel  | badgeIcon
    ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
  `(
    'for issue state $healthStatus, it presents it as a badge with variant "$badgeVariant", label "$badgeLabel" and icon "$badgeIcon"',
    ({ issueState, badgeVariant, badgeLabel, badgeIcon }) => {
      const wrapper = shallowMountExtended(StatePresenter, { propsData: { data: issueState } });
      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props('variant')).toBe(badgeVariant);
      expect(badge.props('icon')).toBe(badgeIcon);
      expect(badge.text()).toBe(badgeLabel);
    },
  );

  it.each`
    mergeRequestState | badgeVariant | badgeLabel  | badgeIcon
    ${'opened'}       | ${'success'} | ${'Open'}   | ${'merge-request-open'}
    ${'closed'}       | ${'danger'}  | ${'Closed'} | ${'merge-request-close'}
    ${'merged'}       | ${'info'}    | ${'Merged'} | ${'merge'}
  `(
    'for merge request state $mergeRequestState, it presents it as a badge with variant "$badgeVariant", label "$badgeLabel" and icon "$badgeIcon"',
    ({ mergeRequestState, badgeVariant, badgeLabel, badgeIcon }) => {
      const wrapper = shallowMountExtended(StatePresenter, {
        propsData: { data: mergeRequestState, source: 'mergeRequests' },
      });
      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props('variant')).toBe(badgeVariant);
      expect(badge.props('icon')).toBe(badgeIcon);
      expect(badge.text()).toBe(badgeLabel);
    },
  );
});
