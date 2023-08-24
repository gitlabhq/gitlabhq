import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventDestroyed from '~/contribution_events/components/contribution_event/contribution_event_destroyed.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { eventDesignDestroyed, eventWikiPageDestroyed, eventMilestoneDestroyed } from '../../utils';

describe('ContributionEventDestroyed', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventDestroyed, {
      propsData,
    });
  };

  describe.each`
    event                                       | expectedMessage                                  | iconName
    ${eventDesignDestroyed()}                   | ${'Archived design in %{resourceParentLink}.'}   | ${'archive'}
    ${eventWikiPageDestroyed()}                 | ${'Deleted wiki page in %{resourceParentLink}.'} | ${'remove'}
    ${eventMilestoneDestroyed()}                | ${'Deleted milestone in %{resourceParentLink}.'} | ${'remove'}
    ${{ target: { type: 'unsupported type' } }} | ${'Deleted resource.'}                           | ${'remove'}
  `('when event target type is $event.target.type', ({ event, expectedMessage, iconName }) => {
    it('renders `ContributionEventBase` with correct props', () => {
      createComponent({ propsData: { event } });

      expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
        event,
        message: expectedMessage,
        iconName,
      });
    });
  });
});
