import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import { createModules } from '~/mr_notes/stores';
import NoteForm from '~/notes/components/note_form.vue';
import MultilineCommentForm from '~/notes/components/multiline_comment_form.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { noteableDataMock } from 'jest/notes/mock_data';
import { getDiffFileMock } from '../mock_data/diff_file';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

describe('DiffLineNoteForm', () => {
  let wrapper;
  let diffFile;
  let diffLines;
  let actions;
  let store;

  const getSelectedLine = () => {
    const lineCode = diffLines[1].line_code;
    return diffFile.highlighted_diff_lines.find((l) => l.line_code === lineCode);
  };

  const createStore = (state) => {
    const modules = createModules();
    modules.diffs.actions = {
      ...modules.diffs.actions,
      saveDiffDiscussion: jest.fn(() => Promise.resolve()),
    };
    modules.diffs.getters = {
      ...modules.diffs.getters,
      diffCompareDropdownTargetVersions: jest.fn(),
      diffCompareDropdownSourceVersions: jest.fn(),
      selectedSourceIndex: jest.fn(),
    };
    modules.notes.getters = {
      ...modules.notes.getters,
      noteableType: jest.fn(),
    };
    actions = modules.diffs.actions;

    store = new Vuex.Store({ modules });
    store.state.notes.userData.id = 1;
    store.state.notes.noteableData = noteableDataMock;

    store.replaceState({ ...store.state, ...state });
  };

  const createComponent = ({ props, state } = {}) => {
    wrapper?.destroy();
    diffFile = getDiffFileMock();
    diffLines = diffFile.highlighted_diff_lines;

    createStore(state);
    store.state.diffs.diffFiles = [diffFile];

    const propsData = {
      diffFileHash: diffFile.file_hash,
      diffLines,
      line: diffLines[1],
      range: { start: diffLines[0], end: diffLines[1] },
      noteTargetLine: diffLines[1],
      ...props,
    };

    wrapper = shallowMount(DiffLineNoteForm, {
      store,
      propsData,
    });
  };

  const findNoteForm = () => wrapper.findComponent(NoteForm);
  const findCommentForm = () => wrapper.findComponent(MultilineCommentForm);

  beforeEach(() => {
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
        await nextTick();

        expect(getSelectedLine().hasForm).toBe(false);
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
      await findNoteForm().vm.$emit('handleFormUpdate', 'note body');
      expect(actions.saveDiffDiscussion.mock.calls[0][1].formData).toMatchObject({
        lineRange,
      });
    });

    it('should save selected line from the store', async () => {
      const lineCode = 'test';
      store.state.notes.selectedCommentPosition = { start: { line_code: lineCode } };
      createComponent({ state: store.state });
      await findNoteForm().vm.$emit('handleFormUpdate', 'note body');
      expect(actions.saveDiffDiscussion.mock.calls[0][1].formData.lineRange.start.line_code).toBe(
        lineCode,
      );
    });
  });
});
