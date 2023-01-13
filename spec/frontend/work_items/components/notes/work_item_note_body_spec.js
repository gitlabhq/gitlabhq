import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemNoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import { mockWorkItemCommentNote } from 'jest/work_items/mock_data';

describe('Work Item Note Body', () => {
  let wrapper;

  const findNoteBody = () => wrapper.findByTestId('work-item-note-body');
  const findNoteEditedText = () => wrapper.findComponent(NoteEditedText);

  const createComponent = ({ note = mockWorkItemCommentNote } = {}) => {
    wrapper = shallowMountExtended(WorkItemNoteBody, {
      propsData: {
        note,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should have the wrapper to show the note body', () => {
    expect(findNoteBody().exists()).toBe(true);
    expect(findNoteBody().html()).toMatchSnapshot();
  });

  it('should not show the edited text when the value is not present', () => {
    expect(findNoteEditedText().exists()).toBe(false);
  });
});
