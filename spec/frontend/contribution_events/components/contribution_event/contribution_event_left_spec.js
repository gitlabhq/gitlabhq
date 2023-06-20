import events from 'test_fixtures/controller/users/activity.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventLeft from '~/contribution_events/components/contribution_event/contribution_event_left.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { eventLeft } from '../../utils';

const defaultPropsData = {
  event: eventLeft(events),
};

describe('ContributionEventLeft', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ContributionEventLeft, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
      event: defaultPropsData.event,
      iconName: 'leave',
    });
  });

  it('renders message', () => {
    expect(wrapper.findByTestId('event-body').text()).toBe(
      `Left project ${defaultPropsData.event.resource_parent.full_name}.`,
    );
  });

  it('renders resource parent link', () => {
    expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(
      defaultPropsData.event,
    );
  });
});
