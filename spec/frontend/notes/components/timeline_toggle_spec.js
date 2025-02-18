import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TimelineToggle, {
  timelineEnabledTooltip,
  timelineDisabledTooltip,
} from '~/notes/components/timeline_toggle.vue';
import { ASC, DESC } from '~/notes/constants';
import createStore from '~/notes/stores';
import { trackToggleTimelineView } from '~/notes/utils';
import Tracking from '~/tracking';

Vue.use(Vuex);

describe('Timeline toggle', () => {
  let wrapper;
  let store;
  const mockEvent = { currentTarget: { blur: jest.fn() } };

  const createComponent = () => {
    jest.spyOn(store, 'dispatch').mockImplementation();
    jest.spyOn(Tracking, 'event').mockImplementation();

    wrapper = mount(TimelineToggle, {
      store,
    });
  };

  const findGlButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    store.dispatch.mockReset();
    mockEvent.currentTarget.blur.mockReset();
    Tracking.event.mockReset();
  });

  describe('ON state', () => {
    it('should update timeline flag in the store', () => {
      store.state.isTimelineEnabled = false;
      findGlButton().vm.$emit('click', mockEvent);
      expect(store.dispatch).toHaveBeenCalledWith('setTimelineView', true);
    });

    it('should set sort direction to DESC if not set', () => {
      store.state.isTimelineEnabled = true;
      store.state.sortDirection = ASC;
      findGlButton().vm.$emit('click', mockEvent);
      expect(store.dispatch).toHaveBeenCalledWith('setDiscussionSortDirection', {
        direction: DESC,
        persist: false,
      });
    });

    it('should set correct UI state', async () => {
      store.state.isTimelineEnabled = true;
      findGlButton().vm.$emit('click', mockEvent);
      await nextTick();
      expect(findGlButton().attributes('title')).toBe(timelineEnabledTooltip);
      expect(findGlButton().props('selected')).toBe(true);
      expect(mockEvent.currentTarget.blur).toHaveBeenCalled();
    });

    it('should track Snowplow event', async () => {
      store.state.isTimelineEnabled = true;
      await nextTick();

      findGlButton().trigger('click');

      const { category, action, label, property, value } = trackToggleTimelineView(true);
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property, value });
    });
  });

  describe('OFF state', () => {
    it('should update timeline flag in the store', () => {
      store.state.isTimelineEnabled = true;
      findGlButton().vm.$emit('click', mockEvent);
      expect(store.dispatch).toHaveBeenCalledWith('setTimelineView', false);
    });

    it('should NOT update sort direction', () => {
      store.state.isTimelineEnabled = false;
      findGlButton().vm.$emit('click', mockEvent);
      expect(store.dispatch).not.toHaveBeenCalledWith();
    });

    it('should set correct UI state', async () => {
      store.state.isTimelineEnabled = false;
      findGlButton().vm.$emit('click', mockEvent);
      await nextTick();
      expect(findGlButton().attributes('title')).toBe(timelineDisabledTooltip);
      expect(findGlButton().attributes('selected')).toBe(undefined);
      expect(mockEvent.currentTarget.blur).toHaveBeenCalled();
    });

    it('should track Snowplow event', async () => {
      store.state.isTimelineEnabled = false;
      await nextTick();

      findGlButton().trigger('click');

      const { category, action, label, property, value } = trackToggleTimelineView(false);
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property, value });
    });
  });
});
