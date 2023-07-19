import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventLeft from '~/contribution_events/components/contribution_event/contribution_event_left.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventLeft } from '../../utils';

const defaultPropsData = {
  event: eventLeft(),
};

describe('ContributionEventLeft', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventLeft, {
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
      message: ContributionEventLeft.i18n.message,
    });
  });
});
