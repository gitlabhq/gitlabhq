import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import WorkItemNote from '~/work_items/components/notes/work_item_note.vue';
import NoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import { mockWorkItemCommentNote } from 'jest/work_items/mock_data';

describe('Work Item Note', () => {
  let wrapper;

  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);
  const findNoteHeader = () => wrapper.findComponent(NoteHeader);
  const findNoteBody = () => wrapper.findComponent(NoteBody);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);

  const createComponent = ({ note = mockWorkItemCommentNote } = {}) => {
    wrapper = shallowMount(WorkItemNote, {
      propsData: {
        note,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Should be wrapped inside the timeline entry item', () => {
    expect(findTimelineEntryItem().exists()).toBe(true);
  });

  it('should have the author avatar of the work item note', () => {
    expect(findAvatarLink().exists()).toBe(true);
    expect(findAvatarLink().attributes('href')).toBe(mockWorkItemCommentNote.author.webUrl);

    expect(findAvatar().exists()).toBe(true);
    expect(findAvatar().props('src')).toBe(mockWorkItemCommentNote.author.avatarUrl);
    expect(findAvatar().props('entityName')).toBe(mockWorkItemCommentNote.author.username);
  });

  it('has note header', () => {
    expect(findNoteHeader().exists()).toBe(true);
    expect(findNoteHeader().props('author')).toEqual(mockWorkItemCommentNote.author);
    expect(findNoteHeader().props('createdAt')).toBe(mockWorkItemCommentNote.createdAt);
  });

  it('has note body', () => {
    expect(findNoteBody().exists()).toBe(true);
    expect(findNoteBody().props('note')).toEqual(mockWorkItemCommentNote);
  });
});
