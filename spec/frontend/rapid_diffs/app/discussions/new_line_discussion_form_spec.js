import { nextTick, reactive } from 'vue';
import { merge } from 'lodash-es';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { stubComponent } from 'helpers/stub_component';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { clearDraft } from '~/lib/utils/autosave';
import { createAlert } from '~/alert';
import { SOMETHING_WENT_WRONG } from '~/diffs/i18n';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import LineRangeHeadline from '~/rapid_diffs/app/discussions/line_range_headline.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';

jest.mock('~/alert');
jest.mock('~/lib/utils/autosave');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('NewLineDiscussionForm', () => {
  let pinia;
  let wrapper;

  const createDiscussion = () => ({
    id: 'new-line-form',
    noteBody: '',
    shouldFocus: false,
    position: {
      old_path: 'file.txt',
      new_path: 'file.txt',
      old_line: null,
      new_line: 10,
    },
  });

  let store;

  const createComponent = (props = {}, provide = {}) => {
    const { discussion = createDiscussion() } = props;
    store.discussionForms = [discussion];
    wrapper = shallowMount(NewLineDiscussionForm, {
      pinia,
      propsData: merge({ discussion }, props),
      provide: merge({ store }, provide),
      stubs: { LineRangeHeadline: stubComponent(LineRangeHeadline) },
    });
  };

  const findNoteForm = () => wrapper.findComponent(NoteForm);
  const findLineRangeHeadline = () => wrapper.findComponent(LineRangeHeadline);

  const withLineRange = (start, end) => ({
    ...createDiscussion(),
    position: {
      ...createDiscussion().position,
      line_range: {
        start: { old_line: null, new_line: start, type: 'new' },
        end: { old_line: null, new_line: end, type: 'new' },
      },
    },
  });

  beforeEach(() => {
    pinia = createTestingPinia({ stubActions: false });
    store = useDiffDiscussions();
    store.createLineDiscussion = jest.fn().mockResolvedValue();
  });

  it('has data-discussion-id attribute', () => {
    createComponent();
    expect(wrapper.find('[data-discussion-id]').element.dataset.discussionId).toBe(
      useDiffDiscussions().discussionForms[0].id,
    );
  });

  it('shows NoteForm component', () => {
    const autosaveKey = '/-file.txt--10';
    createComponent();
    expect(findNoteForm().exists()).toBe(true);
    expect(findNoteForm().props()).toMatchObject({
      autosaveKey,
      autofocus: useDiffDiscussions().discussionForms[0].shouldFocus,
      noteBody: useDiffDiscussions().discussionForms[0].noteBody,
      saveNote: expect.any(Function),
      saveButtonTitle: 'Comment',
      restoreFromAutosave: true,
    });
  });

  it('stops autofocus after first mount', () => {
    createComponent();
    createComponent();
    expect(findNoteForm().props('autofocus')).toBe(false);
  });

  it('updates form value', async () => {
    createComponent();
    const newText = 'new text';
    findNoteForm().vm.$emit('input', newText);
    await nextTick();
    expect(findNoteForm().props('noteBody')).toBe(newText);
  });

  it('cancels reply', async () => {
    createComponent();
    await findNoteForm().vm.$emit('cancel');
    expect(clearDraft).toHaveBeenCalled();
    expect(useDiffDiscussions().discussionForms).toHaveLength(0);
  });

  it('prevents reply cancel when has changed text and dismissed confirm', async () => {
    confirmAction.mockResolvedValue(false);
    createComponent({ discussion: { ...createDiscussion(), noteBody: 'has text' } });
    await findNoteForm().vm.$emit('cancel');
    expect(clearDraft).not.toHaveBeenCalled();
    expect(useDiffDiscussions().discussionForms).toHaveLength(1);
  });

  describe('codeSuggestionsConfig', () => {
    const findNoteFormConfig = () => wrapper.findComponent(NoteForm).props('codeSuggestionsConfig');

    it('passes canSuggest, lines and previewParams from discussion', () => {
      const lines = ['line 1', 'line 2'];
      const previewParams = { preview_suggestions: true, line: 10 };
      createComponent({
        discussion: {
          ...createDiscussion(),
          lines,
          canSuggest: true,
          previewParams,
        },
      });
      const config = findNoteFormConfig();
      expect(config.canSuggest).toBe(true);
      expect(config.lines).toStrictEqual(lines);
      expect(config.previewParams).toStrictEqual(previewParams);
    });

    it('passes blobRawPath from inject', () => {
      const blobRawPath = '/namespace/project/-/raw/abc/file.rb';
      createComponent({}, { blobRawPath });
      expect(findNoteFormConfig().blobRawPath).toBe(blobRawPath);
    });

    it('builds lineRange from position.line_range', () => {
      createComponent({
        discussion: {
          ...createDiscussion(),
          position: {
            ...createDiscussion().position,
            line_range: {
              start: { old_line: null, new_line: 5 },
              end: { old_line: null, new_line: 8 },
            },
          },
        },
      });
      expect(findNoteFormConfig().lineRange).toStrictEqual({ start: 5, end: 8 });
    });

    it('sets lineRange to null when position has no line_range', () => {
      createComponent();
      expect(findNoteFormConfig().lineRange).toBeNull();
    });
  });

  describe('line range info', () => {
    it('passes no line range to the headline when discussion has none', () => {
      createComponent();
      expect(findLineRangeHeadline().props('lineRange')).toBeNull();
    });

    it('passes the discussion line range to the headline', () => {
      const discussion = withLineRange(5, 8);
      createComponent({ discussion });
      expect(findLineRangeHeadline().props('lineRange')).toEqual(discussion.position.line_range);
    });
  });

  describe('focus request', () => {
    it('focuses the comment textarea when shouldFocus becomes true', async () => {
      const discussion = reactive({ ...createDiscussion(), shouldFocus: false });
      store.discussionForms = [discussion];
      wrapper = shallowMount(NewLineDiscussionForm, {
        pinia,
        propsData: { discussion },
        provide: { store },
        stubs: { LineRangeHeadline: stubComponent(LineRangeHeadline) },
      });
      const textarea = document.createElement('textarea');
      wrapper.element.appendChild(textarea);
      const focusSpy = jest.spyOn(textarea, 'focus');

      discussion.shouldFocus = true;
      await nextTick();
      await nextTick();

      expect(focusSpy).toHaveBeenCalled();
    });
  });

  describe('saving note', () => {
    const noteBody = 'Test note body';

    it('calls store.createLineDiscussion with undefined showWhitespace when not provided', async () => {
      const oldDiscussion = createDiscussion();
      createComponent({ props: { discussion: oldDiscussion } });

      await findNoteForm().props('saveNote')(noteBody);

      expect(store.createLineDiscussion).toHaveBeenCalledWith({
        discussion: oldDiscussion,
        noteBody,
        showWhitespace: undefined,
      });
    });

    it('passes injected showWhitespace to store.createLineDiscussion', async () => {
      const oldDiscussion = createDiscussion();
      createComponent({ props: { discussion: oldDiscussion } }, { showWhitespace: false });

      await findNoteForm().props('saveNote')(noteBody);

      expect(store.createLineDiscussion).toHaveBeenCalledWith({
        discussion: oldDiscussion,
        noteBody,
        showWhitespace: false,
      });
    });

    it('shows alert on submission failure', async () => {
      store.createLineDiscussion.mockRejectedValue(new Error('fail'));
      createComponent();

      await findNoteForm().props('saveNote')(noteBody);

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: SOMETHING_WENT_WRONG,
        }),
      );
    });
  });

  describe('draft review support', () => {
    describe('when store has createDraftLineDiscussion', () => {
      beforeEach(() => {
        store.createDraftLineDiscussion = jest.fn().mockResolvedValue();
        store.hasDrafts = false;
      });

      it('passes saveDraft to NoteForm', () => {
        createComponent();
        expect(findNoteForm().props('saveDraft')).toEqual(expect.any(Function));
      });

      it('passes hasDrafts to NoteForm', () => {
        store.hasDrafts = true;
        createComponent();
        expect(findNoteForm().props('hasDrafts')).toBe(true);
      });

      it('calls store.createDraftLineDiscussion on saveDraft', async () => {
        const discussion = createDiscussion();
        createComponent({ discussion });
        await findNoteForm().props('saveDraft')('draft text');
        expect(store.createDraftLineDiscussion).toHaveBeenCalledWith({
          discussion,
          noteBody: 'draft text',
          showWhitespace: undefined,
        });
      });

      it('shows alert on draft save failure', async () => {
        store.createDraftLineDiscussion.mockRejectedValue(new Error('fail'));
        createComponent();
        await findNoteForm().props('saveDraft')('draft text');
        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({ message: SOMETHING_WENT_WRONG }),
        );
      });
    });

    describe('when store does not have createDraftLineDiscussion', () => {
      it('does not pass saveDraft to NoteForm', () => {
        createComponent();
        expect(findNoteForm().props('saveDraft')).toBeNull();
      });
    });
  });
});
