import timezoneMock from 'timezone-mock';
import merge from 'lodash/merge';
import { shallowMountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import IncidentTimelineEventList from '~/issues/show/components/incidents/timeline_events_list.vue';
import { mockEvents } from './mock_data';

describe('IncidentTimelineEventList', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMountExtended(
      IncidentTimelineEventList,
      merge({
        provide: {
          fullPath: 'group/project',
          issuableId: '1',
        },
        propsData: {
          timelineEvents: mockEvents,
        },
      }),
    );
  };

  const findGroups = () => wrapper.findAllByTestId('timeline-group');
  const findItems = (base = wrapper) => base.findAllByTestId('timeline-event');
  const findFirstGroup = () => extendedWrapper(findGroups().at(0));
  const findSecondGroup = () => extendedWrapper(findGroups().at(1));
  const findDates = () => wrapper.findAllByTestId('event-date');

  describe('template', () => {
    it('groups items correctly', () => {
      mountComponent();

      expect(findGroups()).toHaveLength(2);

      expect(findItems(findFirstGroup())).toHaveLength(1);
      expect(findItems(findSecondGroup())).toHaveLength(2);
    });

    it('sets the isLastItem prop correctly', () => {
      mountComponent();

      expect(findItems().at(0).props('isLastItem')).toBe(false);
      expect(findItems().at(1).props('isLastItem')).toBe(false);
      expect(findItems().at(2).props('isLastItem')).toBe(true);
    });

    it('sets the event props correctly', () => {
      mountComponent();

      expect(findItems().at(1).props('occurredAt')).toBe(mockEvents[1].occurredAt);
      expect(findItems().at(1).props('action')).toBe(mockEvents[1].action);
      expect(findItems().at(1).props('noteHtml')).toBe(mockEvents[1].noteHtml);
    });

    it('formats dates correctly', () => {
      mountComponent();

      expect(findDates().at(0).text()).toBe('2022-03-22');
      expect(findDates().at(1).text()).toBe('2022-03-23');
    });

    describe.each`
      timezone
      ${'Europe/London'}
      ${'US/Pacific'}
      ${'Australia/Adelaide'}
    `('when viewing in timezone', ({ timezone }) => {
      describe(timezone, () => {
        beforeEach(() => {
          timezoneMock.register(timezone);

          mountComponent();
        });

        afterEach(() => {
          timezoneMock.unregister();
        });

        it('displays the correct time', () => {
          expect(findDates().at(0).text()).toBe('2022-03-22');
        });
      });
    });
  });
});
