import Vue from 'vue';
import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import { createStore } from '~/mr_notes/stores';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import discussionsMockData from '../mock_data/diff_discussions';

jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(PiniaVuePlugin);

describe('DiffDiscussions', () => {
  let store;
  let pinia;
  let wrapper;
  const getDiscussionsMockData = () => [{ ...discussionsMockData }];

  const createComponent = (props, discussions = getDiscussionsMockData()) => {
    store = createStore();
    wrapper = mount(DiffDiscussions, {
      store,
      pinia,
      propsData: {
        discussions,
        ...props,
      },
    });
  };

  const findNoteableDiscussion = () => wrapper.findComponent(NoteableDiscussion);

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  describe('template', () => {
    it('should have notes list', () => {
      createComponent();

      expect(findNoteableDiscussion().exists()).toBe(true);
      expect(wrapper.findComponent(DiscussionNotes).exists()).toBe(true);
      expect(
        wrapper.findComponent(DiscussionNotes).findAllComponents(TimelineEntryItem).length,
      ).toBe(discussionsMockData.notes.length);
    });
  });

  describe('image commenting', () => {
    const findDiffNotesToggle = () => wrapper.find('.js-diff-notes-toggle');

    it('renders collapsible discussion button', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expandedOnDiff = true;
      createComponent({ shouldCollapseDiscussions: true }, discussions);
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.exists()).toBe(true);
      expect(diffNotesToggle.findComponent(GlIcon).exists()).toBe(true);
      expect(diffNotesToggle.classes('diff-notes-collapse')).toBe(true);
    });

    it('dispatches toggleDiscussion when clicking collapse button', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expandedOnDiff = true;
      createComponent({ shouldCollapseDiscussions: true }, discussions);
      jest.spyOn(store, 'dispatch').mockImplementation();

      findDiffNotesToggle().trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('diffs/toggleFileDiscussion', discussions[0]);
    });

    it('renders expand button when discussion is collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expandedOnDiff = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.text().trim()).toBe('1');
      expect(diffNotesToggle.classes()).toEqual(
        expect.arrayContaining(['js-diff-notes-toggle', '-gl-translate-x-1/2', 'design-note-pin']),
      );
    });

    it('hides discussion when collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expandedOnDiff = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });

      expect(findNoteableDiscussion().isVisible()).toBe(false);
    });

    it('renders badge on avatar', () => {
      createComponent({ renderAvatarBadge: true });
      const noteableDiscussion = findNoteableDiscussion();

      expect(noteableDiscussion.find('.design-note-pin').exists()).toBe(true);
      expect(noteableDiscussion.find('.design-note-pin').text().trim()).toBe('1');
    });
  });
});
