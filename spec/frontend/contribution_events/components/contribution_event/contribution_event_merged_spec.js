import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventMerged from '~/contribution_events/components/contribution_event/contribution_event_merged.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventMerged } from '../../utils';

const defaultPropsData = {
  event: eventMerged(),
};

describe('ContributionEventMerged', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ContributionEventMerged, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toEqual({
      event: defaultPropsData.event,
      iconName: 'merge-request',
      message: ContributionEventMerged.i18n.message,
    });
  });
});
