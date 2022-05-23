import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TimelineEventsTab from '~/issues/show/components/incidents/timeline_events_tab.vue';

describe('TimlineEventsTab', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(TimelineEventsTab);
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findTimelineEventTab = () => wrapper.findComponent(TimelineEventsTab);
  const findNoEventsLine = () => wrapper.find('p');
  const findAddEventButton = () => wrapper.findComponent(GlButton);

  describe('empty state', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the title', () => {
      expect(findTimelineEventTab().attributes('title')).toBe('Timeline');
    });

    it('renders the text', () => {
      expect(findNoEventsLine().exists()).toBe(true);
      expect(findNoEventsLine().text()).toBe('No timeline items have been added yet.');
    });

    it('renders the button', () => {
      expect(findAddEventButton().exists()).toBe(true);
      expect(findAddEventButton().text()).toBe('Add new timeline event');
    });
  });
});
