import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventUpdated from '~/contribution_events/components/contribution_event/contribution_event_updated.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventDesignUpdated, eventWikiPageUpdated } from '../../utils';

describe('ContributionEventUpdated', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventUpdated, {
      propsData,
    });
  };

  describe.each`
    event                                       | expectedMessage
    ${eventDesignUpdated()}                     | ${'Updated design %{targetLink} in %{resourceParentLink}.'}
    ${eventWikiPageUpdated()}                   | ${'Updated wiki page %{targetLink} in %{resourceParentLink}.'}
    ${{ target: { type: 'unsupported type' } }} | ${'Updated resource.'}
  `('when event target type is $event.target.type', ({ event, expectedMessage }) => {
    it('renders `ContributionEventBase` with correct props', () => {
      createComponent({ propsData: { event } });

      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        message: expectedMessage,
        iconName: 'pencil',
      });
    });
  });
});
