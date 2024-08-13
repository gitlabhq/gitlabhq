import { shallowMount } from '@vue/test-utils';
import NotesActivityHeader from '~/notes/components/notes_activity_header.vue';
import DiscussionFilter from '~/notes/components/discussion_filter.vue';
import TimelineToggle from '~/notes/components/timeline_toggle.vue';
import createStore from '~/notes/stores';
import waitForPromises from 'helpers/wait_for_promises';
import { notesFilters } from '../mock_data';

describe('~/notes/components/notes_activity_header.vue', () => {
  let wrapper;

  const findTitle = () => wrapper.find('h2');

  const createComponent = ({ props = {}, ...options } = {}) => {
    wrapper = shallowMount(NotesActivityHeader, {
      propsData: {
        notesFilters,
        ...props,
      },
      // why: Rendering async timeline toggle requires store
      store: createStore(),
      ...options,
    });
  };

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
