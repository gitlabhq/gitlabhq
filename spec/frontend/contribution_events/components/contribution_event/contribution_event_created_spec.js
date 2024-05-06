import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributionEventCreated from '~/contribution_events/components/contribution_event/contribution_event_created.vue';
import ContributionEventBase from '~/contribution_events/components/contribution_event/contribution_event_base.vue';
import { TARGET_TYPE_WORK_ITEM } from '~/contribution_events/constants';
import {
  eventProjectCreated,
  eventMilestoneCreated,
  eventIssueCreated,
  eventMergeRequestCreated,
  eventWikiPageCreated,
  eventDesignCreated,
  eventTaskCreated,
  eventIncidentCreated,
} from '../../utils';

describe('ContributionEventCreated', () => {
  let wrapper;

  const createComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(ContributionEventCreated, {
      propsData,
    });
  };

  describe.each`
    event                                                                        | expectedMessage                                                   | expectedIconName
    ${eventProjectCreated()}                                                     | ${'Created project %{resourceParentLink}.'}                       | ${'status_open'}
    ${eventMilestoneCreated()}                                                   | ${'Opened milestone %{targetLink} in %{resourceParentLink}.'}     | ${'status_open'}
    ${eventIssueCreated()}                                                       | ${'Opened issue %{targetLink} in %{resourceParentLink}.'}         | ${'status_open'}
    ${eventMergeRequestCreated()}                                                | ${'Opened merge request %{targetLink} in %{resourceParentLink}.'} | ${'status_open'}
    ${eventWikiPageCreated()}                                                    | ${'Created wiki page %{targetLink} in %{resourceParentLink}.'}    | ${'status_open'}
    ${eventDesignCreated()}                                                      | ${'Added design %{targetLink} in %{resourceParentLink}.'}         | ${'upload'}
    ${{ resource_parent: { type: 'unsupported type' }, target: { type: null } }} | ${'Created resource.'}                                            | ${'status_open'}
    ${{ target: { type: 'unsupported type' } }}                                  | ${'Created resource.'}                                            | ${'status_open'}
  `(
    'when event target type is $event.target.type',
    ({ event, expectedMessage, expectedIconName }) => {
      it('renders `ContributionEventBase` with correct props', () => {
        createComponent({ propsData: { event } });

        expect(wrapper.findComponent(ContributionEventBase).props()).toMatchObject({
          event,
          message: expectedMessage,
          iconName: expectedIconName,
        });
      });
    },
  );

  describe(`when event target type is ${TARGET_TYPE_WORK_ITEM}`, () => {
    describe.each`
      event                                                                          | expectedMessage
      ${eventTaskCreated()}                                                          | ${'Opened task %{targetLink} in %{resourceParentLink}.'}
      ${eventIncidentCreated()}                                                      | ${'Opened incident %{targetLink} in %{resourceParentLink}.'}
      ${{ target: { type: TARGET_TYPE_WORK_ITEM, issue_type: 'unsupported type' } }} | ${'Created resource.'}
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
