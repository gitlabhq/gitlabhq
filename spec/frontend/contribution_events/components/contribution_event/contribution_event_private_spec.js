import { mountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventPrivate from '~/contribution_events/components/contribution_event/contribution_event_private.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventPrivate } from '../../utils';

const defaultPropsData = {
  event: eventPrivate(),
};

describe('ContributionEventPrivate', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ContributionEventPrivate, {
      propsData: defaultPropsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `ContributionEventBase`', () => {
    expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
      event: defaultPropsData.event,
      iconName: 'eye-slash',
    });
  });

  it('renders message', () => {
    expect(wrapper.findByTestId('event-body').text()).toBe(ContributionEventPrivate.i18n.message);
  });
});
