import timezoneMock from 'timezone-mock';
import merge from 'lodash/merge';
import { GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IncidentTimelineEventListItem from '~/issues/show/components/incidents/timeline_events_list_item.vue';
import { mockEvents } from './mock_data';

describe('IncidentTimelineEventList', () => {
  let wrapper;

  const mountComponent = (propsData) => {
    const { action, noteHtml, occurredAt } = mockEvents[0];
    wrapper = mountExtended(
      IncidentTimelineEventListItem,
      merge({
        propsData: {
          action,
          noteHtml,
          occurredAt,
          isLastItem: false,
          ...propsData,
        },
      }),
    );
  };

  const findCommentIcon = () => wrapper.findComponent(GlIcon);
  const findTextContainer = () => wrapper.findByTestId('event-text-container');
  const findEventTime = () => wrapper.findByTestId('event-time');

  describe('template', () => {
    it('shows comment icon', () => {
      mountComponent();

      expect(findCommentIcon().exists()).toBe(true);
    });

    it('sets correct props for icon', () => {
      mountComponent();

      expect(findCommentIcon().props('name')).toBe(mockEvents[0].action);
    });

    it('displays the correct time', () => {
      mountComponent();

      expect(findEventTime().text()).toBe('15:59 UTC');
    });

    describe('last item in list', () => {
      it('shows a bottom border when not the last item', () => {
        mountComponent();

        expect(findTextContainer().classes()).toContain('gl-border-1');
      });

      it('does not show a bottom border when the last item', () => {
        mountComponent({ isLastItem: true });

        expect(wrapper.classes()).not.toContain('gl-border-1');
      });
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
          expect(findEventTime().text()).toBe('15:59 UTC');
        });
      });
    });
  });
});
