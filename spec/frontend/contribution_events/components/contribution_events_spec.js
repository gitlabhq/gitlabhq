import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import ContributionEventApproved from '~/contribution_events/components/contribution_event/contribution_event_approved.vue';
import ContributionEventExpired from '~/contribution_events/components/contribution_event/contribution_event_expired.vue';
import ContributionEventJoined from '~/contribution_events/components/contribution_event/contribution_event_joined.vue';
import ContributionEventLeft from '~/contribution_events/components/contribution_event/contribution_event_left.vue';
import ContributionEventPushed from '~/contribution_events/components/contribution_event/contribution_event_pushed.vue';
import ContributionEventPrivate from '~/contribution_events/components/contribution_event/contribution_event_private.vue';
import ContributionEventMerged from '~/contribution_events/components/contribution_event/contribution_event_merged.vue';
import ContributionEventCreated from '~/contribution_events/components/contribution_event/contribution_event_created.vue';
import {
  eventApproved,
  eventExpired,
  eventJoined,
  eventLeft,
  eventPushedBranch,
  eventPrivate,
  eventMerged,
  eventCreated,
} from '../utils';

describe('ContributionEvents', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEvents, {
      propsData: {
        events: [
          eventApproved(),
          eventExpired(),
          eventJoined(),
          eventLeft(),
          eventPushedBranch(),
          eventPrivate(),
          eventMerged(),
          eventCreated(),
        ],
      },
    });
  };

  it.each`
    expectedComponent            | expectedEvent
    ${ContributionEventApproved} | ${eventApproved()}
    ${ContributionEventExpired}  | ${eventExpired()}
    ${ContributionEventJoined}   | ${eventJoined()}
    ${ContributionEventLeft}     | ${eventLeft()}
    ${ContributionEventPushed}   | ${eventPushedBranch()}
    ${ContributionEventPrivate}  | ${eventPrivate()}
    ${ContributionEventMerged}   | ${eventMerged()}
    ${ContributionEventCreated}  | ${eventCreated()}
  `(
    'renders `$expectedComponent.name` component and passes expected event',
    ({ expectedComponent, expectedEvent }) => {
      createComponent();

      expect(wrapper.findComponent(expectedComponent).props('event')).toEqual(expectedEvent);
    },
  );
});
