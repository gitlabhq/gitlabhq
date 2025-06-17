import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import TimelineToggle, {
  timelineEnabledTooltip,
  timelineDisabledTooltip,
} from '~/notes/components/timeline_toggle.vue';
import { ASC, DESC } from '~/notes/constants';
import { trackToggleTimelineView } from '~/notes/utils';
import Tracking from '~/tracking';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('Timeline toggle', () => {
  let wrapper;
  let pinia;
  const mockEvent = { currentTarget: { blur: jest.fn() } };

  const createComponent = () => {
    jest.spyOn(Tracking, 'event').mockImplementation();

    wrapper = mount(TimelineToggle, {
      pinia,
    });
  };

  const findGlButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin], stubActions: false });
    useLegacyDiffs();
    useNotes();
  });

  afterEach(() => {
    mockEvent.currentTarget.blur.mockReset();
    Tracking.event.mockReset();
  });

  describe('ON state', () => {
    it('should update timeline flag in the store', () => {
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      expect(useNotes().setTimelineView).toHaveBeenCalledWith(true);
    });

    it('should set sort direction to DESC if not set', () => {
      useNotes().discussionSortOrder = ASC;
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      expect(useNotes().setDiscussionSortDirection).toHaveBeenCalledWith({
        direction: DESC,
        persist: false,
      });
    });

    it('should set correct UI state', async () => {
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      await nextTick();
      expect(findGlButton().attributes('title')).toBe(timelineEnabledTooltip);
      expect(findGlButton().props('selected')).toBe(true);
      expect(mockEvent.currentTarget.blur).toHaveBeenCalled();
    });

    it('should track Snowplow event', async () => {
      createComponent();
      await nextTick();

      findGlButton().trigger('click');

      const { category, action, label, property, value } = trackToggleTimelineView(true);
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property, value });
    });
  });

  describe('OFF state', () => {
    beforeEach(() => {
      useNotes().isTimelineEnabled = true;
    });

    it('should update timeline flag in the store', () => {
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      expect(useNotes().setTimelineView).toHaveBeenCalledWith(false);
    });

    it('should NOT update sort direction', () => {
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      expect(useNotes().setDiscussionSortDirection).not.toHaveBeenCalled();
    });

    it('should set correct UI state', async () => {
      createComponent();
      findGlButton().vm.$emit('click', mockEvent);
      await nextTick();
      expect(findGlButton().attributes('title')).toBe(timelineDisabledTooltip);
      expect(findGlButton().attributes('selected')).toBe(undefined);
      expect(mockEvent.currentTarget.blur).toHaveBeenCalled();
    });

    it('should track Snowplow event', () => {
      createComponent();

      findGlButton().trigger('click');

      const { category, action, label, property, value } = trackToggleTimelineView(false);
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property, value });
    });
  });
});
