import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatePresenter from '~/glql/components/presenters/state.vue';

describe('StatePresenter', () => {
  it.each`
    source             | issueState  | badgeVariant | badgeLabel  | badgeIcon
    ${'issues'}        | ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'issues'}        | ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'workItems'}     | ${'OPEN'}   | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'workItems'}     | ${'CLOSED'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'mergeRequests'} | ${'opened'} | ${'success'} | ${'Open'}   | ${'merge-request-open'}
    ${'mergeRequests'} | ${'closed'} | ${'danger'}  | ${'Closed'} | ${'merge-request-close'}
    ${'mergeRequests'} | ${'merged'} | ${'info'}    | ${'Merged'} | ${'merge'}
  `(
    'for $source state $issueState, it presents it as a badge with variant "$badgeVariant", label "$badgeLabel" and icon "$badgeIcon"',
    ({ issueState, badgeVariant, badgeLabel, badgeIcon, source }) => {
      const wrapper = shallowMountExtended(StatePresenter, {
        propsData: { data: issueState, source },
      });
      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props('variant')).toBe(badgeVariant);
      expect(badge.props('icon')).toBe(badgeIcon);
      expect(badge.text()).toBe(badgeLabel);
    },
  );
});
