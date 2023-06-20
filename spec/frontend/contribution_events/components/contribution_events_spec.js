import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { EVENT_TYPE_APPROVED } from '~/contribution_events/constants';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import ContributionEventApproved from '~/contribution_events/components/contribution_event/contribution_event_approved.vue';

const eventApproved = events.find((event) => event.action === EVENT_TYPE_APPROVED);

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
    ${ContributionEventApproved} | ${eventApproved}
  `(
    'renders `$expectedComponent.name` component and passes expected event',
    ({ expectedComponent, expectedEvent }) => {
      createComponent();

      expect(wrapper.findComponent(expectedComponent).props('event')).toEqual(expectedEvent);
    },
  );
});
