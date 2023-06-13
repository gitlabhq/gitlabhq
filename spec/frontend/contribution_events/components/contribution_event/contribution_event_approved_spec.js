import events from 'test_fixtures/controller/users/activity.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { EVENT_TYPE_APPROVED } from '~/contribution_events/constants';
import ContributionEventApproved from '~/contribution_events/components/contribution_event/contribution_event_approved.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import TargetLink from '~/contribution_events/components/target_link.vue';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';

const eventApproved = events.find((event) => event.action === EVENT_TYPE_APPROVED);

describe('ContributionEventApproved', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ContributionEventApproved, {
      propsData: {
        event: eventApproved,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toEqual({
      event: eventApproved,
      iconName: 'approval-solid',
      iconClass: 'gl-text-green-500',
    });
  });

  it('renders message', () => {
    expect(wrapper.findByTestId('event-body').text()).toBe(
      `Approved merge request ${eventApproved.target.reference_link_text} in ${eventApproved.resource_parent.full_name}.`,
    );
  });

  it('renders target link', () => {
    expect(wrapper.findComponent(TargetLink).props('event')).toEqual(eventApproved);
  });

  it('renders resource parent link', () => {
    expect(wrapper.findComponent(ResourceParentLink).props('event')).toEqual(eventApproved);
  });
});
