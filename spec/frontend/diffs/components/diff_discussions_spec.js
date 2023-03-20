import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import { createStore } from '~/mr_notes/stores';
import DiscussionNotes from '~/notes/components/discussion_notes.vue';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import discussionsMockData from '../mock_data/diff_discussions';

jest.mock('~/behaviors/markdown/render_gfm');

describe('DiffDiscussions', () => {
  let store;
  let wrapper;
  const getDiscussionsMockData = () => [{ ...discussionsMockData }];

  const createComponent = (props) => {
    store = createStore();
    wrapper = mount(DiffDiscussions, {
      store,
      propsData: {
        discussions: getDiscussionsMockData(),
        ...props,
      },
    });
  };

  describe('template', () => {
    it('should have notes list', () => {
      createComponent();

      expect(wrapper.findComponent(NoteableDiscussion).exists()).toBe(true);
      expect(wrapper.findComponent(DiscussionNotes).exists()).toBe(true);
      expect(
        wrapper.findComponent(DiscussionNotes).findAllComponents(TimelineEntryItem).length,
      ).toBe(discussionsMockData.notes.length);
    });
  });

  describe('image commenting', () => {
    const findDiffNotesToggle = () => wrapper.find('.js-diff-notes-toggle');

    it('renders collapsible discussion button', () => {
      createComponent({ shouldCollapseDiscussions: true });
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.exists()).toBe(true);
      expect(diffNotesToggle.findComponent(GlIcon).exists()).toBe(true);
      expect(diffNotesToggle.classes('diff-notes-collapse')).toBe(true);
    });

    it('dispatches toggleDiscussion when clicking collapse button', () => {
      createComponent({ shouldCollapseDiscussions: true });
      jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation();
      const diffNotesToggle = findDiffNotesToggle();
      diffNotesToggle.trigger('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('toggleDiscussion', {
        discussionId: discussionsMockData.id,
      });
    });

    it('renders expand button when discussion is collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expanded = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });
      const diffNotesToggle = findDiffNotesToggle();

      expect(diffNotesToggle.text().trim()).toBe('1');
      expect(diffNotesToggle.classes()).toEqual(
        expect.arrayContaining(['js-diff-notes-toggle', 'gl-translate-x-n50', 'design-note-pin']),
      );
    });

    it('hides discussion when collapsed', () => {
      const discussions = getDiscussionsMockData();
      discussions[0].expanded = false;
      createComponent({ discussions, shouldCollapseDiscussions: true });

      expect(wrapper.findComponent(NoteableDiscussion).isVisible()).toBe(false);
    });

    it('renders badge on avatar', () => {
      createComponent({ renderAvatarBadge: true });
      const noteableDiscussion = wrapper.findComponent(NoteableDiscussion);

      expect(noteableDiscussion.find('.design-note-pin').exists()).toBe(true);
      expect(noteableDiscussion.find('.design-note-pin').text().trim()).toBe('1');
    });
  });
});
