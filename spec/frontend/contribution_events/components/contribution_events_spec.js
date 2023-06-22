import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import ContributionEventApproved from '~/contribution_events/components/contribution_event/contribution_event_approved.vue';
import ContributionEventExpired from '~/contribution_events/components/contribution_event/contribution_event_expired.vue';
import ContributionEventJoined from '~/contribution_events/components/contribution_event/contribution_event_joined.vue';
import ContributionEventLeft from '~/contribution_events/components/contribution_event/contribution_event_left.vue';
import { eventApproved, eventExpired, eventJoined, eventLeft } from '../utils';

describe('ContributionEvents', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEvents, {
      propsData: {
        events,
      },
    });
  };

  it.each`
    expectedComponent            | expectedEvent
    ${ContributionEventApproved} | ${eventApproved()}
    ${ContributionEventExpired}  | ${eventExpired()}
    ${ContributionEventJoined}   | ${eventJoined()}
    ${ContributionEventLeft}     | ${eventLeft()}
  `(
    'renders `$expectedComponent.name` component and passes expected event',
    ({ expectedComponent, expectedEvent }) => {
      createComponent();

      expect(wrapper.findComponent(expectedComponent).props('event')).toEqual(expectedEvent);
    },
  );
});
