import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemNoteBody from '~/work_items/components/notes/work_item_note_body.vue';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import { mockWorkItemCommentNote } from 'jest/work_items/mock_data';

describe('Work Item Note Body', () => {
  let wrapper;

  const findNoteBody = () => wrapper.findByTestId('work-item-note-body');
  const findNoteEditedText = () => wrapper.findComponent(NoteEditedText);

  const createComponent = ({ note = mockWorkItemCommentNote, hasAdminNotePermission } = {}) => {
    wrapper = shallowMountExtended(WorkItemNoteBody, {
      propsData: {
        hasAdminNotePermission,
        note,
      },
    });
  };

  it('should have the wrapper to show the note body', () => {
    createComponent();

    expect(findNoteBody().html()).toMatchSnapshot();
  });

  it('should not show the edited text when the value is not present', () => {
    createComponent();

    expect(findNoteEditedText().exists()).toBe(false);
  });

  it('emits "updateNote" event to update markdown when toggling checkbox', () => {
    const markdownBefore = `beginning

- [ ] one
- [ ] two
- [ ] three

end`;
    const markdownAfter = `beginning

- [x] one
- [ ] two
- [ ] three

end`;
    const note = {
      ...mockWorkItemCommentNote,
      body: markdownBefore,
      bodyHtml:
        '<p data-sourcepos="1:1-1:9" dir="auto">beginning</p>&#x000A;<ul data-sourcepos="3:1-6:0" class="task-list" dir="auto">&#x000A;<li data-sourcepos="3:1-3:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> one</li>&#x000A;<li data-sourcepos="4:1-4:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> two</li>&#x000A;<li data-sourcepos="5:1-6:0" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> three</li>&#x000A;</ul>&#x000A;<p data-sourcepos="7:1-7:3" dir="auto">end</p>',
    };
    createComponent({ note, hasAdminNotePermission: true });
    const checkbox = wrapper.find('.task-list-item-checkbox').element;

    checkbox.checked = true;
    checkbox.dispatchEvent(new CustomEvent('change', { bubbles: true }));

    expect(wrapper.emitted('updateNote')).toEqual([
      [{ commentText: markdownAfter, executeOptimisticResponse: false }],
    ]);
  });

  it('updates checkbox state when "isUpdating" watcher updates', async () => {
    const markdownBefore = `beginning

- [ ] one
- [ ] two
- [ ] three

end`;
    const note = {
      ...mockWorkItemCommentNote,
      body: markdownBefore,
      bodyHtml:
        '<p data-sourcepos="1:1-1:9" dir="auto">beginning</p>&#x000A;<ul data-sourcepos="3:1-6:0" class="task-list" dir="auto">&#x000A;<li data-sourcepos="3:1-3:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> one</li>&#x000A;<li data-sourcepos="4:1-4:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> two</li>&#x000A;<li data-sourcepos="5:1-6:0" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> three</li>&#x000A;</ul>&#x000A;<p data-sourcepos="7:1-7:3" dir="auto">end</p>',
    };
    createComponent({ note, hasAdminNotePermission: true });
    await nextTick();
    const checkboxes = Array.from(wrapper.element.querySelectorAll('.task-list-item-checkbox'));

    expect(checkboxes.every((checkbox) => checkbox.disabled === false)).toBe(true);

    await wrapper.setProps({ isUpdating: true });

    expect(checkboxes.every((checkbox) => checkbox.disabled === true)).toBe(true);
  });

  describe('when user does not have adminNote permission', () => {
    it('disables all checkboxes', async () => {
      const markdownBefore = `beginning

- [ ] one
- [ ] two
- [ ] three

end`;
      const note = {
        ...mockWorkItemCommentNote,
        body: markdownBefore,
        bodyHtml:
          '<p data-sourcepos="1:1-1:9" dir="auto">beginning</p>&#x000A;<ul data-sourcepos="3:1-6:0" class="task-list" dir="auto">&#x000A;<li data-sourcepos="3:1-3:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> one</li>&#x000A;<li data-sourcepos="4:1-4:9" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> two</li>&#x000A;<li data-sourcepos="5:1-6:0" class="task-list-item">&#x000A;<task-button></task-button><input type="checkbox" class="task-list-item-checkbox" disabled> three</li>&#x000A;</ul>&#x000A;<p data-sourcepos="7:1-7:3" dir="auto">end</p>',
      };
      createComponent({ note });
      await nextTick();
      const checkboxes = Array.from(wrapper.element.querySelectorAll('.task-list-item-checkbox'));

      expect(checkboxes.every((checkbox) => checkbox.disabled === true)).toBe(true);
    });
  });
});
