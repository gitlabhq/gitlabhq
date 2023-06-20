import { shallowMount } from '@vue/test-utils';
import WorkItemNoteReplying from '~/work_items/components/notes/work_item_note_replying.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

describe('Work Item Note Replying', () => {
  let wrapper;
  const mockNoteBody = 'replying body';

  const findTimelineEntry = () => wrapper.findComponent(TimelineEntryItem);
  const findNoteHeader = () => wrapper.findComponent(NoteHeader);

  const createComponent = ({ body = mockNoteBody, isInternalNote = false } = {}) => {
    wrapper = shallowMount(WorkItemNoteReplying, {
      propsData: {
        body,
        isInternalNote,
      },
    });

    window.gon.current_user_id = '1';
    window.gon.current_user_avatar_url = 'avatar.png';
    window.gon.current_user_fullname = 'Administrator';
    window.gon.current_username = 'user';
  };

  beforeEach(() => {
    createComponent();
  });

  it('should have the note body and header', () => {
    expect(findTimelineEntry().exists()).toBe(true);
    expect(findNoteHeader().html()).toMatchSnapshot();
  });

  it('should have the correct class when internal note', () => {
    createComponent({ isInternalNote: true });
    expect(findTimelineEntry().classes()).toContain('internal-note');
  });
});
