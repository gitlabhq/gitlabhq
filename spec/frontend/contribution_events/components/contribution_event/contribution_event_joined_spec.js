import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventJoined from '~/contribution_events/components/contribution_event/contribution_event_joined.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventJoined } from '../../utils';

const defaultPropsData = {
  event: eventJoined(),
};

describe('ContributionEventJoined', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventJoined, {
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
      message: ContributionEventJoined.i18n.message,
    });
  });
});
