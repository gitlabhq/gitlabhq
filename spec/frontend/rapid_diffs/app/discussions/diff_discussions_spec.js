import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import setWindowLocation from 'helpers/set_window_location_helper';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import NoteableDiscussion from '~/rapid_diffs/app/discussions/noteable_discussion.vue';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { markAsScrolled } from '~/rapid_diffs/utils/scroll_to_linked_fragment';

jest.mock('~/rapid_diffs/utils/scroll_to_linked_fragment', () => ({
  hasScrolled: jest.fn().mockReturnValue(false),
  markAsScrolled: jest.fn(),
}));

jest.mock('~/lib/utils/sticky', () => ({
  scrollPastCoveringElements: jest.fn(),
}));

describe('DiffDiscussions', () => {
  let pinia;
  let wrapper;
  let store;

  const linkedFileData = { old_path: 'file.js', new_path: 'file.js' };
  const filePaths = { oldPath: 'file.js', newPath: 'file.js' };

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMount(DiffDiscussions, {
      pinia,
      propsData: props,
      provide: { store, ...provide },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
    store = useDiffDiscussions();
  });

  it('renders noteable discussions', () => {
    const discussion1 = { id: '1' };
    const discussion2 = { id: '2' };
    createComponent({ discussions: [discussion1, discussion2] });
    expect(
      wrapper
        .findAllComponents(NoteableDiscussion)
        .wrappers.map((component) => component.props('discussion')),
    ).toStrictEqual([discussion1, discussion2]);
  });

  it('provides data', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    const props = wrapper.findComponent(NoteableDiscussion).props();
    props.requestLastNoteEditing();
    expect(props.discussion).toBe(discussion);
    expect(useDiffDiscussions().requestLastNoteEditing).toHaveBeenCalled();
  });

  it('passes toggleResolveNote to NoteableDiscussion', () => {
    store.toggleResolveNote = jest.fn();
    createComponent({ discussions: [{ id: '1' }] });
    expect(wrapper.findComponent(NoteableDiscussion).props('toggleResolveNote')).toBe(
      store.toggleResolveNote,
    );
  });

  it('handles startReplying event', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('startReplying');
    expect(useDiffDiscussions().startReplying).toHaveBeenCalledWith(discussion);
  });

  it('handles stopReplying event', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('stopReplying');
    expect(useDiffDiscussions().stopReplying).toHaveBeenCalledWith(discussion);
  });

  it('toggles replies', () => {
    const discussion = { id: '1' };
    createComponent({ discussions: [discussion] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('toggleDiscussionReplies');
    expect(useDiffDiscussions().toggleDiscussionReplies).toHaveBeenCalledWith(discussion);
  });

  it('handles startEditing event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('startEditing', note);
    expect(useDiffDiscussions().setEditingMode).toHaveBeenCalledWith(note, true);
  });

  it('handles cancelEditing event', () => {
    const note = { id: '1' };
    createComponent({ discussions: [{ id: '1' }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('cancelEditing', note);
    expect(useDiffDiscussions().setEditingMode).toHaveBeenCalledWith(note, false);
  });

  it('handles noteEdited event', () => {
    const note = { id: '1' };
    const value = 'edit';
    createComponent({ discussions: [{ id: '1', notes: [note] }] });
    wrapper.findComponent(NoteableDiscussion).vm.$emit('noteEdited', { note, value });
    expect(useDiffDiscussions().editNote).toHaveBeenCalledWith({ note, value });
  });

  describe('timelineLayout prop', () => {
    it('passes timelineLayout to NoteableDiscussion', () => {
      createComponent({ discussions: [{ id: '1' }], timelineLayout: true });
      expect(wrapper.findComponent(NoteableDiscussion).props('timelineLayout')).toBe(true);
    });

    it('defaults timelineLayout to false', () => {
      createComponent({ discussions: [{ id: '1' }] });
      expect(wrapper.findComponent(NoteableDiscussion).props('timelineLayout')).toBe(false);
    });
  });

  describe('isLastDiscussion prop', () => {
    it('passes isLastDiscussion as true for the last discussion', () => {
      createComponent({ discussions: [{ id: '1' }, { id: '2' }] });
      const discussions = wrapper.findAllComponents(NoteableDiscussion);
      expect(discussions.at(0).props('isLastDiscussion')).toBe(false);
      expect(discussions.at(1).props('isLastDiscussion')).toBe(true);
    });

    it('passes isLastDiscussion as true for single discussion', () => {
      createComponent({ discussions: [{ id: '1' }] });
      expect(wrapper.findComponent(NoteableDiscussion).props('isLastDiscussion')).toBe(true);
    });
  });

  it('shows counter badge', () => {
    createComponent({ discussions: [{ id: '1' }], counterBadgeVisible: true });
    expect(wrapper.findComponent(DesignNotePin).exists()).toBe(true);
    expect(wrapper.findComponent(DesignNotePin).props()).toMatchObject({
      label: 1,
      size: 'sm',
      clickable: false,
    });
  });

  describe('scrollToNoteFragment', () => {
    let noteElement;

    beforeEach(() => {
      noteElement = document.createElement('div');
      noteElement.id = 'note_123';
      noteElement.innerHTML = '<a href="/mr/1#note_123"></a>';
      noteElement.scrollIntoView = jest.fn();
      document.body.appendChild(noteElement);

      setWindowLocation('https://example.com/diffs#note_123');
      jest.spyOn(window.history, 'replaceState').mockImplementation(() => {});
    });

    afterEach(() => {
      noteElement.remove();
    });

    it('scrolls to note and applies highlight when linked file matches', () => {
      const link = noteElement.querySelector('a');
      jest.spyOn(link, 'click').mockImplementation(() => {});
      const discussions = [{ id: '1', notes: [{ id: 123 }] }];
      createComponent({ discussions }, { linkedFileData, filePaths });
      expect(noteElement.scrollIntoView).toHaveBeenCalledWith({ block: 'start' });
      expect(window.history.replaceState).toHaveBeenCalled();
      expect(markAsScrolled).toHaveBeenCalled();
    });

    it('does not scroll when linkedFileData is not provided', () => {
      const discussions = [{ id: '1', notes: [{ id: 123 }] }];
      createComponent({ discussions }, { filePaths });
      expect(noteElement.scrollIntoView).not.toHaveBeenCalled();
    });

    it('does not scroll when file paths do not match', () => {
      const discussions = [{ id: '1', notes: [{ id: 123 }] }];
      const mismatchedFilePaths = { oldPath: 'other.js', newPath: 'other.js' };
      createComponent({ discussions }, { linkedFileData, filePaths: mismatchedFilePaths });
      expect(noteElement.scrollIntoView).not.toHaveBeenCalled();
    });

    it('does not scroll when note element is not in the DOM', () => {
      noteElement.remove();
      setWindowLocation('https://example.com/diffs#note_999');
      const discussions = [{ id: '1', notes: [{ id: 999 }] }];
      createComponent({ discussions }, { linkedFileData, filePaths });
      expect(markAsScrolled).not.toHaveBeenCalled();
    });
  });
});
