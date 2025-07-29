import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import NoteForm from '~/notes/components/note_form.vue';
import MultilineCommentForm from '~/notes/components/multiline_comment_form.vue';
import { clearDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { noteableDataMock } from 'jest/notes/mock_data';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useBatchComments } from '~/batch_comments/store';
import { useNotes } from '~/notes/store/legacy_notes';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { getDiffFileMock } from '../mock_data/diff_file';

jest.mock('~/lib/utils/autosave');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/alert');

Vue.use(PiniaVuePlugin);

describe('DiffLineNoteForm', () => {
  let wrapper;
  let pinia;
  let diffFile;
  let diffLines;

  const createComponent = ({ props } = {}) => {
    const propsData = {
      diffFileHash: diffFile.file_hash,
      diffLines,
      line: diffLines[1],
      range: { start: diffLines[0], end: diffLines[1] },
      noteTargetLine: diffLines[1],
      ...props,
    };

    wrapper = shallowMount(DiffLineNoteForm, {
      propsData,
      pinia,
    });
  };

  const findNoteForm = () => wrapper.findComponent(NoteForm);
  const findCommentForm = () => wrapper.findComponent(MultilineCommentForm);

  beforeEach(() => {
    diffFile = getDiffFileMock();
    diffLines = diffFile.highlighted_diff_lines;

    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs().diffFiles = [diffFile];
    useLegacyDiffs().saveDiffDiscussion.mockResolvedValue();
    useNotes().userData = { id: 1 };
    useNotes().noteableData = noteableDataMock;
    useBatchComments().saveDraft.mockResolvedValue();
    useMrNotes();
    createComponent();
  });

  it('shows note form', () => {
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
  });

  it('passes the provided range of lines to comment form', () => {
    expect(findCommentForm().props('lineRange')).toMatchObject({
      start: diffLines[0],
      end: diffLines[1],
    });
  });

  it('respects empty range when passing a range of lines', () => {
    createComponent({ props: { range: null } });
    expect(findCommentForm().props('lineRange')).toMatchObject({
      start: diffLines[1],
      end: diffLines[1],
    });
  });

  describe('when cancelling form', () => {
    afterEach(() => {
      confirmAction.mockReset();
    });

    it('should only ask for confirmation once', () => {
      let finalizePromise;
      confirmAction.mockImplementation(
        () =>
          new Promise((resolve) => {
            finalizePromise = resolve;
          }),
      );

      findNoteForm().vm.$emit('cancelForm', true, true);
      findNoteForm().vm.$emit('cancelForm', true, true);

      expect(confirmAction).toHaveBeenCalledTimes(1);
      finalizePromise();
    });

    describe('with confirmation', () => {
      beforeEach(() => {
        confirmAction.mockResolvedValueOnce(true);
      });

      it('should ask form confirmation and hide form for a line', async () => {
        findNoteForm().vm.$emit('cancelForm', true, true);
        await nextTick();
        expect(confirmAction).toHaveBeenCalled();
        await waitForPromises();

        expect(useLegacyDiffs().cancelCommentForm).toHaveBeenCalledWith({
          lineCode: diffLines[1].line_code,
          fileHash: diffFile.file_hash,
        });
      });

      it('should clear the autosaved draft', async () => {
        findNoteForm().vm.$emit('cancelForm', true, true);
        await nextTick();
        expect(confirmAction).toHaveBeenCalled();
        await waitForPromises();

        expect(clearDraft).toHaveBeenCalledWith(
          `Note/Issue/${noteableDataMock.id}//DiffNote//${diffLines[1].line_code}`,
        );
      });
    });

    describe('without confirmation', () => {
      beforeEach(() => {
        confirmAction.mockResolvedValueOnce(false);
      });

      it('should ask for confirmation when shouldConfirm and isDirty passed as truthy', () => {
        findNoteForm().vm.$emit('cancelForm', true, true);

        expect(confirmAction).toHaveBeenCalled();
      });

      it('should not ask for confirmation when one of the params false', () => {
        findNoteForm().vm.$emit('cancelForm', true, false);

        expect(confirmAction).not.toHaveBeenCalled();

        findNoteForm().vm.$emit('cancelForm', false, true);

        expect(confirmAction).not.toHaveBeenCalled();
      });
    });
  });

  describe('saving note', () => {
    beforeEach(() => {
      useNotes().noteableData.merge_params = {};
    });

    it('should save original line', async () => {
      const lineRange = {
        start: {
          line_code: diffLines[1].line_code,
          type: diffLines[1].type,
          new_line: 2,
          old_line: null,
        },
        end: {
          line_code: diffLines[1].line_code,
          type: diffLines[1].type,
          new_line: 2,
          old_line: null,
        },
      };

      const noteBody = 'note body';
      await findNoteForm().vm.$emit('handleFormUpdate', noteBody);

      expect(useLegacyDiffs().saveDiffDiscussion).toHaveBeenCalledWith({
        note: noteBody,
        formData: {
          noteableData: noteableDataMock,
          noteableType: useNotes().noteableType,
          noteTargetLine: diffLines[1],
          diffViewType: useLegacyDiffs().diffViewType,
          diffFile,
          linePosition: '',
          lineRange,
        },
      });
      expect(useLegacyDiffs().cancelCommentForm).toHaveBeenCalledWith({
        lineCode: diffLines[1].line_code,
        fileHash: diffFile.file_hash,
      });
    });

    it('should save selected line from the store', async () => {
      const lineCode = 'test';
      useNotes().selectedCommentPosition = { start: { line_code: lineCode } };
      createComponent();
      const noteBody = 'note body';

      await findNoteForm().vm.$emit('handleFormUpdate', noteBody);

      expect(useLegacyDiffs().saveDiffDiscussion).toHaveBeenCalledWith({
        note: noteBody,
        formData: {
          noteableData: noteableDataMock,
          noteableType: useNotes().noteableType,
          noteTargetLine: diffLines[1],
          diffViewType: useLegacyDiffs().diffViewType,
          diffFile,
          linePosition: '',
          lineRange: {
            start: {
              line_code: lineCode,
              new_line: undefined,
              old_line: undefined,
              type: undefined,
            },
            end: {
              line_code: diffLines[1].line_code,
              new_line: diffLines[1].new_line,
              old_line: diffLines[1].old_line,
              type: diffLines[1].type,
            },
          },
        },
      });
      expect(useLegacyDiffs().cancelCommentForm).toHaveBeenCalledWith({
        lineCode: diffLines[1].line_code,
        fileHash: diffFile.file_hash,
      });
    });

    describe('when note-form emits `handleFormUpdate`', () => {
      const noteStub = 'invalid note';
      const parentElement = null;
      const errorCallback = jest.fn();

      describe.each`
        scenario                  | serverError                      | message
        ${'with server error'}    | ${{ data: { errors: 'error' } }} | ${SAVING_THE_COMMENT_FAILED}
        ${'without server error'} | ${null}                          | ${SOMETHING_WENT_WRONG}
      `('$scenario', ({ serverError, message }) => {
        beforeEach(async () => {
          useLegacyDiffs().saveDiffDiscussion.mockRejectedValue({ response: serverError });

          createComponent();

          await findNoteForm().vm.$emit('handleFormUpdate', noteStub, parentElement, errorCallback);

          await waitForPromises();
        });

        it(`renders ${serverError ? 'server' : 'generic'} error message`, () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: sprintf(message, { reason: serverError?.data?.errors }),
            parent: parentElement,
          });
        });

        it('calls errorCallback', () => {
          expect(errorCallback).toHaveBeenCalled();
        });
      });
    });
  });
});
