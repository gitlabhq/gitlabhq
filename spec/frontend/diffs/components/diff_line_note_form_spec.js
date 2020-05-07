import { shallowMount } from '@vue/test-utils';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import NoteForm from '~/notes/components/note_form.vue';
import { createStore } from '~/mr_notes/stores';
import diffFileMockData from '../mock_data/diff_file';
import { noteableDataMock } from '../../notes/mock_data';

describe('DiffLineNoteForm', () => {
  let wrapper;
  let diffFile;
  let diffLines;
  const getDiffFileMock = () => ({ ...diffFileMockData });

  beforeEach(() => {
    diffFile = getDiffFileMock();
    diffLines = diffFile.highlighted_diff_lines;
    const store = createStore();
    store.state.notes.userData.id = 1;
    store.state.notes.noteableData = noteableDataMock;

    wrapper = shallowMount(DiffLineNoteForm, {
      store,
      propsData: {
        diffFileHash: diffFile.file_hash,
        diffLines,
        line: diffLines[0],
        noteTargetLine: diffLines[0],
      },
    });
  });

  describe('methods', () => {
    describe('handleCancelCommentForm', () => {
      it('should ask for confirmation when shouldConfirm and isDirty passed as truthy', () => {
        jest.spyOn(window, 'confirm').mockReturnValue(false);

        wrapper.vm.handleCancelCommentForm(true, true);

        expect(window.confirm).toHaveBeenCalled();
      });

      it('should ask for confirmation when one of the params false', () => {
        jest.spyOn(window, 'confirm').mockReturnValue(false);

        wrapper.vm.handleCancelCommentForm(true, false);

        expect(window.confirm).not.toHaveBeenCalled();

        wrapper.vm.handleCancelCommentForm(false, true);

        expect(window.confirm).not.toHaveBeenCalled();
      });

      it('should call cancelCommentForm with lineCode', done => {
        jest.spyOn(window, 'confirm').mockImplementation(() => {});
        jest.spyOn(wrapper.vm, 'cancelCommentForm').mockImplementation(() => {});
        jest.spyOn(wrapper.vm, 'resetAutoSave').mockImplementation(() => {});
        wrapper.vm.handleCancelCommentForm();

        expect(window.confirm).not.toHaveBeenCalled();
        wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.cancelCommentForm).toHaveBeenCalledWith({
            lineCode: diffLines[0].line_code,
            fileHash: wrapper.vm.diffFileHash,
          });

          expect(wrapper.vm.resetAutoSave).toHaveBeenCalled();

          done();
        });
      });
    });

    describe('saveNoteForm', () => {
      it('should call saveNote action with proper params', done => {
        const saveDiffDiscussionSpy = jest
          .spyOn(wrapper.vm, 'saveDiffDiscussion')
          .mockReturnValue(Promise.resolve());

        wrapper.vm
          .handleSaveNote('note body')
          .then(() => {
            expect(saveDiffDiscussionSpy).toHaveBeenCalledWith({
              note: 'note body',
              formData: wrapper.vm.formData,
            });
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('mounted', () => {
    it('should init autosave', () => {
      const key = 'autosave/Note/Issue/98//DiffNote//1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_1';

      expect(wrapper.vm.autosave).toBeDefined();
      expect(wrapper.vm.autosave.key).toEqual(key);
    });
  });

  describe('template', () => {
    it('should have note form', () => {
      expect(wrapper.find(NoteForm).exists()).toBe(true);
    });
  });
});
