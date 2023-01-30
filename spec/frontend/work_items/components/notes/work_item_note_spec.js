import { GlAvatarLink } from '@gitlab/ui';
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
});
