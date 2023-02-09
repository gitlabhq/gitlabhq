import { GlAvatarLink, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/work_items/components/notes/work_item_note_actions.vue';
import { mockWorkItemCommentNote } from 'jest/work_items/mock_data';

describe('Work Item Note', () => {
  let wrapper;

  const findAuthorAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findNoteHeader = () => wrapper.findComponent(NoteHeader);
  const findNoteBody = () => wrapper.findComponent(NoteBody);
  const findNoteActions = () => wrapper.findComponent(NoteActions);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDeleteNoteButton = () => wrapper.find('[data-testid="delete-note-action"]');

  const createComponent = ({ note = mockWorkItemCommentNote, isFirstNote = false } = {}) => {
    wrapper = shallowMount(WorkItemNote, {
      propsData: {
        note,
        isFirstNote,
      },
    });
  };

  describe('Main comment', () => {
    beforeEach(() => {
      createComponent({ isFirstNote: true });
    });

    it('Should have the note header, actions and body', () => {
      expect(findTimelineEntryItem().exists()).toBe(true);
      expect(findNoteHeader().exists()).toBe(true);
      expect(findNoteBody().exists()).toBe(true);
      expect(findNoteActions().exists()).toBe(true);
    });

    it('Should not have the Avatar link for main thread inside the timeline-entry', () => {
      expect(findAuthorAvatarLink().exists()).toBe(false);
    });

    it('Should have the reply button props', () => {
      expect(findNoteActions().props('showReply')).toBe(true);
    });
  });

  describe('Comment threads', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Should have the note header, actions and body', () => {
      expect(findTimelineEntryItem().exists()).toBe(true);
      expect(findNoteHeader().exists()).toBe(true);
      expect(findNoteBody().exists()).toBe(true);
      expect(findNoteActions().exists()).toBe(true);
    });

    it('Should have the Avatar link for comment threads', () => {
      expect(findAuthorAvatarLink().exists()).toBe(true);
    });

    it('Should not have the reply button props', () => {
      expect(findNoteActions().props('showReply')).toBe(false);
    });
  });

  it('should display a dropdown if user has a permission to delete note', () => {
    createComponent({
      note: {
        ...mockWorkItemCommentNote,
        userPermissions: { ...mockWorkItemCommentNote.userPermissions, adminNote: true },
      },
    });

    expect(findDropdown().exists()).toBe(true);
  });

  it('should not display a dropdown if user has no permission to delete note', () => {
    createComponent();

    expect(findDropdown().exists()).toBe(false);
  });

  it('should emit `deleteNote` event when delete note action is clicked', () => {
    createComponent({
      note: {
        ...mockWorkItemCommentNote,
        userPermissions: { ...mockWorkItemCommentNote.userPermissions, adminNote: true },
      },
    });

    findDeleteNoteButton().vm.$emit('click');

    expect(wrapper.emitted('deleteNote')).toEqual([[]]);
  });
});
