import events from 'test_fixtures/controller/users/activity.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventJoined from '~/contribution_events/components/contribution_event/contribution_event_joined.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { eventJoined } from '../../utils';

const defaultPropsData = {
  event: eventJoined(events),
};

describe('ContributionEventJoined', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ContributionEventJoined, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
      event: defaultPropsData.event,
      iconName: 'users',
    });
  });

  it('renders message', () => {
    expect(wrapper.findByTestId('event-body').text()).toBe(
      `Joined project ${defaultPropsData.event.resource_parent.full_name}.`,
    );
  });

  it('renders resource parent link', () => {
    expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(
      defaultPropsData.event,
    );
  });
});
