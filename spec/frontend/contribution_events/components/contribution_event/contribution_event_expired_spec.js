import events from 'test_fixtures/controller/users/activity.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventExpired from '~/contribution_events/components/contribution_event/contribution_event_expired.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { eventExpired } from '../../utils';

const defaultPropsData = {
  event: eventExpired(events),
};

describe('ContributionEventExpired', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ContributionEventExpired, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
      event: defaultPropsData.event,
      iconName: 'expire',
    });
  });

  it('renders message', () => {
    expect(wrapper.findByTestId('event-body').text()).toBe(
      `Removed due to membership expiration from ${defaultPropsData.event.resource_parent.full_name}.`,
    );
  });

  it('renders resource parent link', () => {
    expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(
      defaultPropsData.event,
    );
  });
});
