import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventClosed from '~/contribution_events/components/contribution_event/contribution_event_closed.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_WORK_ITEM } from '~/contribution_events/constants';
import {
  eventMilestoneClosed,
  eventIssueClosed,
  eventMergeRequestClosed,
  eventTaskClosed,
  eventIncidentClosed,
} from '../../utils';

describe('ContributionEventClosed', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventClosed, {
      propsData,
    });
  };

  describe.each`
    event                                       | expectedMessage                                                   | iconName
    ${eventMilestoneClosed()}                   | ${'Closed milestone %{targetLink} in %{resourceParentLink}.'}     | ${'status_closed'}
    ${eventIssueClosed()}                       | ${'Closed issue %{targetLink} in %{resourceParentLink}.'}         | ${'issue-closed'}
    ${eventMergeRequestClosed()}                | ${'Closed merge request %{targetLink} in %{resourceParentLink}.'} | ${'merge-request-close'}
    ${{ target: { type: 'unsupported type' } }} | ${'Closed resource.'}                                             | ${'status_closed'}
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

  describe(`when event target type is ${TARGET_TYPE_WORK_ITEM}`, () => {
    describe.each`
      event                                                                          | expectedMessage
      ${eventTaskClosed()}                                                           | ${'Closed task %{targetLink} in %{resourceParentLink}.'}
      ${eventIncidentClosed()}                                                       | ${'Closed incident %{targetLink} in %{resourceParentLink}.'}
      ${{ target: { type: TARGET_TYPE_WORK_ITEM, issue_type: 'unsupported type' } }} | ${'Closed resource.'}
    `('when issue type is $event.target.issue_type', ({ event, expectedMessage }) => {
      it('renders `ContributionEventBase` with correct props', () => {
        createComponent({ propsData: { event } });

        expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
          event,
          message: expectedMessage,
          iconName: 'status_closed',
        });
      });
    });
  });
});
