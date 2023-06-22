import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventExpired from '~/contribution_events/components/contribution_event/contribution_event_expired.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventExpired } from '../../utils';

const defaultPropsData = {
  event: eventExpired(),
};

describe('ContributionEventExpired', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventExpired, {
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
      message: ContributionEventExpired.i18n.message,
    });
  });
});
