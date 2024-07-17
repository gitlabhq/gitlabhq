import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventReopened from '~/contribution_events/components/contribution_event/contribution_event_reopened.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_WORK_ITEM } from '~/contribution_events/constants';
import {
  eventMilestoneReopened,
  eventIssueReopened,
  eventMergeRequestReopened,
  eventTaskReopened,
  eventIncidentReopened,
} from '../../utils';

describe('ContributionEventReopened', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventReopened, {
      propsData,
    });
  };

  describe.each`
    event                                       | expectedMessage                                                     | iconName
    ${eventMilestoneReopened()}                 | ${'Reopened milestone %{targetLink} in %{resourceParentLink}.'}     | ${'status_open'}
    ${eventIssueReopened()}                     | ${'Reopened issue %{targetLink} in %{resourceParentLink}.'}         | ${'status_open'}
    ${eventMergeRequestReopened()}              | ${'Reopened merge request %{targetLink} in %{resourceParentLink}.'} | ${'merge-request'}
    ${{ target: { type: 'unsupported type' } }} | ${'Reopened resource.'}                                             | ${'status_open'}
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
      ${eventTaskReopened()}                                                         | ${'Reopened task %{targetLink} in %{resourceParentLink}.'}
      ${eventIncidentReopened()}                                                     | ${'Reopened incident %{targetLink} in %{resourceParentLink}.'}
      ${{ target: { type: TARGET_TYPE_WORK_ITEM, issue_type: 'unsupported type' } }} | ${'Reopened resource.'}
    `('when issue type is $event.target.issue_type', ({ event, expectedMessage }) => {
      it('renders `ContributionEventBase` with correct props', () => {
        createComponent({ propsData: { event } });

        expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
          event,
          message: expectedMessage,
          iconName: 'status_open',
        });
      });
    });
  });
});
