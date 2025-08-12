import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatePresenter from '~/glql/components/presenters/state.vue';

describe('StatePresenter', () => {
  it.each`
    source            | state       | badgeVariant | badgeLabel  | badgeIcon
    ${'Issue'}        | ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'Issue'}        | ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'WorkItem'}     | ${'OPEN'}   | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'WorkItem'}     | ${'CLOSED'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'Epic'}         | ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'Epic'}         | ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'MergeRequest'} | ${'opened'} | ${'success'} | ${'Open'}   | ${'merge-request-open'}
    ${'MergeRequest'} | ${'closed'} | ${'danger'}  | ${'Closed'} | ${'merge-request-close'}
    ${'MergeRequest'} | ${'merged'} | ${'info'}    | ${'Merged'} | ${'merge'}
  `(
    'for $source state $state, it presents it as a badge with variant "$badgeVariant", label "$badgeLabel" and icon "$badgeIcon"',
    ({ state, badgeVariant, badgeLabel, badgeIcon, source }) => {
      const wrapper = shallowMountExtended(StatePresenter, {
        propsData: { data: state, item: { __typename: source, state } },
      });
      const badge = wrapper.findComponent(GlBadge);

      expect(badge.props('variant')).toBe(badgeVariant);
      expect(badge.props('icon')).toBe(badgeIcon);
      expect(badge.text()).toBe(badgeLabel);
    },
  );
});
