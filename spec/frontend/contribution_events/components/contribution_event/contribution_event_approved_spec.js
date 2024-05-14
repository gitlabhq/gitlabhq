import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventApproved from '~/contribution_events/components/contribution_event/contribution_event_approved.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventApproved } from '../../utils';

const defaultPropsData = {
  event: eventApproved(),
};

describe('ContributionEventApproved', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventApproved, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toEqual({
      event: defaultPropsData.event,
      iconName: 'approval-solid',
      message: ContributionEventApproved.i18n.message,
    });
  });
});
