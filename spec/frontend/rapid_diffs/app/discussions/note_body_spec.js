import { shallowMount } from '@vue/test-utils';
import NoteBody from '~/rapid_diffs/app/discussions/note_body.vue';
import NoteAttachment from '~/notes/components/note_attachment.vue';
import NoteEditedText from '~/notes/components/note_edited_text.vue';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';

describe('NoteBody', () => {
  let wrapper;
  let defaultProps;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NoteBody, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findNoteText = () => wrapper.find('.test-note-content');
  const findNoteForm = () => wrapper.findComponent(NoteForm);
  const findHiddenTextarea = () => wrapper.find('textarea');
  const findNoteEditedText = () => wrapper.findComponent(NoteEditedText);
  const findAwardsList = () => wrapper.findComponent(AwardsList);
  const findNoteAttachment = () => wrapper.findComponent(NoteAttachment);

  beforeEach(() => {
    defaultProps = {
      note: {
        id: '123',
        note: 'Test note content',
        note_html: '<p class="test-note-content">Test note content</p>',
        path: '/notes/123',
        internal: false,
        author: {
          id: 1,
        },
        current_user: {
          can_award_emoji: true,
        },
      },
      saveNote: jest.fn().mockResolvedValue(),
      canEdit: false,
      isEditing: false,
    };
    window.gon = {
      current_user_id: 1,
    };
  });

  it('renders note text with gfm directive', () => {
    createComponent();
    const noteText = findNoteText();
    expect(noteText.exists()).toBe(true);
  });

  describe('note form', () => {
    it('does not show form when not editing', () => {
      createComponent({ isEditing: false });
      expect(findNoteForm().exists()).toBe(false);
    });

    it('shows form when editing', () => {
      createComponent({ isEditing: true });
      const form = findNoteForm();
      expect(form.exists()).toBe(true);
      expect(form.props()).toMatchObject({
        noteBody: defaultProps.note.note,
        noteId: defaultProps.note.id,
        saveButtonTitle: 'Save comment',
        autosaveKey: '',
        restoreFromAutosave: false,
        saveNote: defaultProps.saveNote,
      });
    });

    it('uses edited note', () => {
      const editedNote = 'edit';
      createComponent({
        isEditing: true,
        note: {
          ...defaultProps.note,
          editedNote,
        },
      });
      expect(findNoteForm().props('noteBody')).toBe(editedNote);
    });

    it('passes autosave key to form', () => {
      const autosaveKey = 'test-autosave-key';
      createComponent({ isEditing: true, autosaveKey });
      expect(findNoteForm().props('autosaveKey')).toBe(autosaveKey);
    });

    it('passes restore from autosave to form', () => {
      createComponent({ isEditing: true, restoreFromAutosave: true });
      expect(findNoteForm().props('restoreFromAutosave')).toBe(true);
    });

    it('shows internal note save button title for internal notes', () => {
      createComponent({
        isEditing: true,
        note: { ...defaultProps.note, internal: true },
      });
      expect(findNoteForm().props('saveButtonTitle')).toBe('Save internal note');
    });

    it('emits input event when form input changes', () => {
      createComponent({ isEditing: true });
      findNoteForm().vm.$emit('input', 'updated content');
      expect(wrapper.emitted('input')).toStrictEqual([['updated content']]);
    });

    it('emits cancelEditing event when form is cancelled', () => {
      createComponent({ isEditing: true });
      findNoteForm().vm.$emit('cancel', true);
      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[true]]);
    });
  });

  describe('hidden textarea', () => {
    it('does not show when cannot edit', () => {
      createComponent({ canEdit: false });
      expect(findHiddenTextarea().exists()).toBe(false);
    });

    it('shows when can edit', () => {
      createComponent({ canEdit: true });
      const field = findHiddenTextarea();
      expect(field.exists()).toBe(true);
      expect(field.attributes('data-update-url')).toBe(defaultProps.note.path);
    });
  });

  describe('note edited text', () => {
    it('does not show when note has not been edited', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          last_edited_at: null,
          created_at: '2024-01-01',
        },
      });
      expect(findNoteEditedText().exists()).toBe(false);
    });

    it('does not show when last edited time equals created time', () => {
      const timestamp = '2024-01-01T10:00:00Z';
      createComponent({
        note: {
          ...defaultProps.note,
          last_edited_at: timestamp,
          created_at: timestamp,
        },
      });
      expect(findNoteEditedText().exists()).toBe(false);
    });

    it('shows when note has been edited', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          last_edited_at: '2024-01-02T10:00:00Z',
          last_edited_by: { name: 'John Doe' },
          created_at: '2024-01-01T10:00:00Z',
        },
      });
      const editedText = findNoteEditedText();
      expect(editedText.exists()).toBe(true);
      expect(editedText.props()).toMatchObject({
        editedAt: '2024-01-02T10:00:00Z',
        editedBy: { name: 'John Doe' },
        actionText: 'Edited',
      });
    });
  });

  describe('awards list', () => {
    it('does not show when note has no awards', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          award_emoji: [],
        },
      });
      expect(findAwardsList().exists()).toBe(false);
    });

    it('does not show when award_emoji is undefined', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          award_emoji: undefined,
        },
      });
      expect(findAwardsList().exists()).toBe(false);
    });

    it('shows when note has awards', () => {
      const awards = [
        { name: 'thumbsup', user: { id: 1 } },
        { name: 'heart', user: { id: 2 } },
      ];
      createComponent({
        note: {
          ...defaultProps.note,
          award_emoji: awards,
        },
      });
      const awardsList = findAwardsList();
      expect(awardsList.exists()).toBe(true);
      expect(awardsList.props()).toMatchObject({
        awards,
        canAwardEmoji: true,
        currentUserId: 1,
      });
    });

    it('emits award event when award is toggled', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          award_emoji: [{ name: 'thumbsup', user: { id: 1 } }],
        },
      });
      findAwardsList().vm.$emit('award', 'thumbsup');
      expect(wrapper.emitted('award')).toStrictEqual([['thumbsup']]);
    });
  });

  describe('note attachment', () => {
    it('does not show when note has no attachment', () => {
      createComponent({
        note: {
          ...defaultProps.note,
          attachment: null,
        },
      });
      expect(findNoteAttachment().exists()).toBe(false);
    });

    it('shows when note has attachment', () => {
      const attachment = {
        url: 'https://example.com/file.pdf',
        filename: 'file.pdf',
      };
      createComponent({
        note: {
          ...defaultProps.note,
          attachment,
        },
      });
      const noteAttachment = findNoteAttachment();
      expect(noteAttachment.exists()).toBe(true);
      expect(noteAttachment.props('attachment')).toEqual(attachment);
    });
  });
});
