import { nextTick } from 'vue';
import { merge } from 'lodash';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { clearDraft } from '~/lib/utils/autosave';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';
import NewLineDiscussionForm from '~/rapid_diffs/app/discussions/new_line_discussion_form.vue';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');
jest.mock('~/lib/utils/autosave');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');

describe('NewLineDiscussionForm', () => {
  let mockAdapter;
  let pinia;
  let wrapper;

  const defaultProvisions = {
    endpoints: {
      discussions: '/discussions',
    },
  };

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

  const createComponent = (props = {}, provide = {}) => {
    const { discussion = createDiscussion() } = props;
    useDiffDiscussions().discussions = [discussion];
    wrapper = shallowMount(NewLineDiscussionForm, {
      pinia,
      propsData: merge({ discussion }, props),
      provide: merge(defaultProvisions, provide),
    });
  };

  const findNoteForm = () => wrapper.findComponent(NoteForm);

  beforeEach(() => {
    mockAdapter = new MockAdapter(axios);
    pinia = createTestingPinia({ stubActions: false });
  });

  it('has data-discussion-id attribute', () => {
    createComponent();
    expect(wrapper.find('[data-discussion-id]').element.dataset.discussionId).toBe(
      useDiffDiscussions().discussions[0].id,
    );
  });

  it('shows NoteForm component', () => {
    const autosaveKey = '/-file.txt--10';
    createComponent();
    expect(findNoteForm().exists()).toBe(true);
    expect(findNoteForm().props()).toMatchObject({
      autosaveKey,
      autofocus: useDiffDiscussions().discussions[0].shouldFocus,
      noteBody: useDiffDiscussions().discussions[0].noteBody,
      saveNote: expect.any(Function),
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
    expect(useDiffDiscussions().discussions).toHaveLength(0);
  });

  it('prevents reply cancel when has changed text and dismissed confirm', async () => {
    confirmAction.mockResolvedValue(false);
    createComponent({ discussion: { ...createDiscussion(), noteBody: 'has text' } });
    await findNoteForm().vm.$emit('cancel');
    expect(clearDraft).not.toHaveBeenCalled();
    expect(useDiffDiscussions().discussions).toHaveLength(1);
  });

  describe('saving note', () => {
    const noteBody = 'Test note body';
    const newDiscussion = { id: 'new-discussion' };

    it('submits discussion and replaces form', async () => {
      const oldDiscussion = createDiscussion();
      mockAdapter
        .onPost(defaultProvisions.endpoints.discussions, {
          note_text: noteBody,
          position: oldDiscussion.position,
        })
        .reply(HTTP_STATUS_OK, { discussion: newDiscussion });
      createComponent({ props: { discussion: oldDiscussion } });

      await findNoteForm().props('saveNote')(noteBody);

      expect(clearDraft).toHaveBeenCalled();
      expect(useDiffDiscussions().replaceDiscussion).toHaveBeenCalledWith(
        oldDiscussion,
        newDiscussion,
      );
    });

    it('shows alert on submission failure', async () => {
      mockAdapter
        .onPost(defaultProvisions.endpoints.discussions)
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();

      await findNoteForm().props('saveNote')(noteBody);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to submit your comment. Please try again.',
        parent: expect.any(Object),
        error: expect.any(Object),
      });
      expect(clearDraft).not.toHaveBeenCalled();
      expect(useDiffDiscussions().replaceDiscussion).not.toHaveBeenCalled();
    });
  });
});
