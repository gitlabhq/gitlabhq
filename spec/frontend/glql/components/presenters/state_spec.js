import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatePresenter from '~/glql/components/presenters/state.vue';
import { MOCK_MERGE_REQUESTS_DIMENSIONS } from '../../mock_data';

describe('StatePresenter', () => {
  it.each`
    source                                          | state       | badgeVariant | badgeLabel  | badgeIcon
    ${'Issue'}                                      | ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'Issue'}                                      | ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'WorkItem'}                                   | ${'OPEN'}   | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'WorkItem'}                                   | ${'CLOSED'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'Epic'}                                       | ${'opened'} | ${'success'} | ${'Open'}   | ${'issue-open-m'}
    ${'Epic'}                                       | ${'closed'} | ${'info'}    | ${'Closed'} | ${'issue-close'}
    ${'MergeRequest'}                               | ${'opened'} | ${'success'} | ${'Open'}   | ${'merge-request-open'}
    ${'MergeRequest'}                               | ${'closed'} | ${'danger'}  | ${'Closed'} | ${'merge-request-close'}
    ${'MergeRequest'}                               | ${'merged'} | ${'info'}    | ${'Merged'} | ${'merge'}
    ${'MergeRequestsAggregationResponseDimensions'} | ${'opened'} | ${'success'} | ${'Open'}   | ${'merge-request-open'}
    ${'MergeRequestsAggregationResponseDimensions'} | ${'closed'} | ${'danger'}  | ${'Closed'} | ${'merge-request-close'}
    ${'MergeRequestsAggregationResponseDimensions'} | ${'merged'} | ${'info'}    | ${'Merged'} | ${'merge'}
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

  it('presents locked merge request analytics states with a neutral badge', () => {
    const wrapper = shallowMountExtended(StatePresenter, {
      propsData: {
        data: 'locked',
        item: { ...MOCK_MERGE_REQUESTS_DIMENSIONS, state: 'locked' },
      },
    });
    const badge = wrapper.findComponent(GlBadge);

    expect(badge.props('variant')).toBe('neutral');
    expect(badge.text()).toBe('Locked');
  });

  it('falls back to a neutral badge with the normalized state for unmapped states', () => {
    const wrapper = shallowMountExtended(StatePresenter, {
      propsData: {
        data: 'MERGED',
        item: { __typename: 'Issue', state: 'MERGED' },
      },
    });
    const badge = wrapper.findComponent(GlBadge);

    expect(badge.props('variant')).toBe('neutral');
    expect(badge.props('icon')).toBeNull();
    expect(badge.text()).toBe('Merged');
  });
});
