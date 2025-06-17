import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import NotesActivityHeader from '~/notes/components/notes_activity_header.vue';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import TimelineToggle from '~/notes/components/timeline_toggle.vue';
import createStore from '~/notes/stores';
import waitForPromises from 'helpers/wait_for_promises';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { notesFilters } from '../mock_data';

Vue.use(PiniaVuePlugin);

describe('~/notes/components/notes_activity_header.vue', () => {
  let wrapper;
  let pinia;

  const findTitle = () => wrapper.find('h2');

  const createComponent = ({ props = {}, ...options } = {}) => {
    wrapper = shallowMount(NotesActivityHeader, {
      propsData: {
        notesFilters,
        ...props,
      },
      // why: Rendering async timeline toggle requires store
      store: createStore(),
      pinia,
      ...options,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin],
    });
    useLegacyDiffs();
    useNotes();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders title', () => {
      expect(findTitle().text()).toBe('Activity');
    });

    it('renders discussion filter', () => {
      expect(wrapper.findComponent(DiscussionFilter).props()).toEqual({
        filters: notesFilters,
        selectedValue: 0,
      });
    });

    it('does not render timeline toggle', () => {
      expect(wrapper.findComponent(TimelineToggle).exists()).toBe(false);
    });
  });

  it('with notesFilterValue prop, passes to discussion filter', () => {
    createComponent({ props: { notesFilterValue: 1 } });

    expect(wrapper.findComponent(DiscussionFilter).props('selectedValue')).toBe(1);
  });

  it('with showTimelineViewToggle injected, renders timeline toggle asynchronously', async () => {
    createComponent({ provide: { showTimelineViewToggle: () => true } });

    expect(wrapper.findComponent(TimelineToggle).exists()).toBe(false);

    await waitForPromises();

    expect(wrapper.findComponent(TimelineToggle).exists()).toBe(true);
  });
});
