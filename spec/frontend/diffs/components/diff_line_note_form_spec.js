import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import { createStore } from '~/mr_notes/stores';
import NoteForm from '~/notes/components/note_form.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { noteableDataMock } from 'jest/notes/mock_data';
import diffFileMockData from '../mock_data/diff_file';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal', () => {
  return {
    confirmAction: jest.fn(),
  };
});

describe('DiffLineNoteForm', () => {
  let wrapper;
  let diffFile;
  let diffLines;
  const getDiffFileMock = () => ({ ...diffFileMockData });

  const createComponent = (args = {}) => {
    diffFile = getDiffFileMock();
    diffLines = diffFile.highlighted_diff_lines;
    const store = createStore();
    store.state.notes.userData.id = 1;
    store.state.notes.noteableData = noteableDataMock;
    store.state.diffs.diffFiles = [diffFile];

    store.replaceState({ ...store.state, ...args.state });

    return shallowMount(DiffLineNoteForm, {
      store,
      propsData: {
        ...{
          diffFileHash: diffFile.file_hash,
          diffLines,
          line: diffLines[1],
          range: { start: diffLines[0], end: diffLines[1] },
          noteTargetLine: diffLines[1],
        },
        ...(args.props || {}),
      },
    });
  };

  const findNoteForm = () => wrapper.findComponent(NoteForm);

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('handleCancelCommentForm', () => {
      afterEach(() => {
        confirmAction.mockReset();
      });

      it('should ask for confirmation when shouldConfirm and isDirty passed as truthy', () => {
        confirmAction.mockResolvedValueOnce(false);

        findNoteForm().vm.$emit('cancelForm', true, true);

        expect(confirmAction).toHaveBeenCalled();
      });

      it('should not ask for confirmation when one of the params false', () => {
        confirmAction.mockResolvedValueOnce(false);

        findNoteForm().vm.$emit('cancelForm', true, false);

        expect(confirmAction).not.toHaveBeenCalled();

        findNoteForm().vm.$emit('cancelForm', false, true);

        expect(confirmAction).not.toHaveBeenCalled();
      });

      it('should call cancelCommentForm with lineCode', async () => {
        confirmAction.mockResolvedValueOnce(true);
        jest.spyOn(wrapper.vm, 'cancelCommentForm').mockImplementation(() => {});
        jest.spyOn(wrapper.vm, 'resetAutoSave').mockImplementation(() => {});

        findNoteForm().vm.$emit('cancelForm', true, true);

        await nextTick();

        expect(confirmAction).toHaveBeenCalled();

        await nextTick();

        expect(wrapper.vm.cancelCommentForm).toHaveBeenCalledWith({
          lineCode: diffLines[1].line_code,
          fileHash: wrapper.vm.diffFileHash,
        });
        expect(wrapper.vm.resetAutoSave).toHaveBeenCalled();
      });
    });

    describe('saveNoteForm', () => {
      it('should call saveNote action with proper params', async () => {
        const saveDiffDiscussionSpy = jest
          .spyOn(wrapper.vm, 'saveDiffDiscussion')
          .mockReturnValue(Promise.resolve());

        const lineRange = {
          start: {
            line_code: wrapper.vm.commentLineStart.line_code,
            type: wrapper.vm.commentLineStart.type,
            new_line: 2,
            old_line: null,
          },
          end: {
            line_code: wrapper.vm.line.line_code,
            type: wrapper.vm.line.type,
            new_line: 2,
            old_line: null,
          },
        };

        const formData = {
          ...wrapper.vm.formData,
          lineRange,
        };

        await wrapper.vm.handleSaveNote('note body');
        expect(saveDiffDiscussionSpy).toHaveBeenCalledWith({
          note: 'note body',
          formData,
        });
      });
    });
  });

  describe('created', () => {
    it('should use the provided `range` of lines', () => {
      wrapper = createComponent();

      expect(wrapper.vm.lines.start).toBe(diffLines[0]);
      expect(wrapper.vm.lines.end).toBe(diffLines[1]);
    });

    it("should fill the internal `lines` data with the provided `line` if there's no provided `range", () => {
      wrapper = createComponent({ props: { range: null } });

      expect(wrapper.vm.lines.start).toBe(diffLines[1]);
      expect(wrapper.vm.lines.end).toBe(diffLines[1]);
    });
  });

  describe('mounted', () => {
    it('should init autosave', () => {
      const key = 'autosave/Note/Issue/98//DiffNote//1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_2';
      wrapper = createComponent();

      expect(wrapper.vm.autosave).toBeDefined();
      expect(wrapper.vm.autosave.key).toEqual(key);
    });

    it('should set selectedCommentPosition', () => {
      wrapper = createComponent();
      let startLineCode = wrapper.vm.commentLineStart.line_code;
      let lineCode = wrapper.vm.line.line_code;

      expect(startLineCode).toEqual(lineCode);
      wrapper.destroy();

      const state = {
        notes: {
          selectedCommentPosition: {
            start: {
              line_code: 'test',
            },
          },
        },
      };
      wrapper = createComponent({ state });
      startLineCode = wrapper.vm.commentLineStart.line_code;
      lineCode = state.notes.selectedCommentPosition.start.line_code;
      expect(startLineCode).toEqual(lineCode);
    });
  });

  describe('template', () => {
    it('should have note form', () => {
      wrapper = createComponent();
      expect(wrapper.find(NoteForm).exists()).toBe(true);
    });
  });
});
