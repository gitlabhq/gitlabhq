import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useDiscussions } from '~/notes/store/discussions';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import LineRangeHeadline from '~/rapid_diffs/app/discussions/line_range_headline.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { useBatchComments } from '~/batch_comments/store';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

Vue.use(PiniaVuePlugin);

const NoteFormStub = {
  name: 'NoteForm',
  props: { noteBody: String, noteId: Number, isDraft: Boolean },
  template: '<div></div>',
};

const lineRange = {
  start: { new_line: 1, type: 'new' },
  end: { new_line: 2, type: 'new' },
};

describe('Batch comments draft preview item component', () => {
  let wrapper;
  let pinia;
  let draft;

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useDiscussions();
    useLegacyDiffs();
    useNotes();
  });

  function createComponent(extra = {}) {
    draft = {
      ...createDraft(),
      ...extra,
    };

    wrapper = mountExtended(PreviewItem, {
      pinia,
      propsData: { draft },
      stubs: { NoteForm: NoteFormStub },
      attachTo: document.body,
    });
  }

  const setDiscussion = (discussion) => {
    useDiscussions().discussions = [
      { id: '1', notes: [{ author: { name: "Author 'Nick' Name" } }], ...discussion },
    ];
  };

  const findTitle = () => wrapper.findByTestId('review-preview-item-header-text');
  const findHeaderButton = () => wrapper.findByTestId('preview-item-header');
  const findContent = () => wrapper.findByTestId('review-preview-item-content');
  const findDraftResolution = () => wrapper.findByTestId('draft-note-resolution');
  const findLineRangeHeadline = () => wrapper.findComponent(LineRangeHeadline);
  const findEditButton = () => wrapper.findComponentByTestId('preview-item-edit');
  const findDeleteButton = () => wrapper.findComponentByTestId('preview-item-delete');
  const findNoteForm = () => wrapper.findComponent(NoteFormStub);
  const findInternalNoteBadge = () => wrapper.findByTestId('internal-note-indicator');

  const startEditing = async () => {
    createComponent();
    await findEditButton().vm.$emit('click');
  };

  it('renders the note HTML as markdown', async () => {
    createComponent({ note_html: '<p>Hello <strong>world</strong></p>' });
    await nextTick();

    expect(findContent().element.innerHTML).toBe('<p>Hello <strong>world</strong></p>');
    expect(renderGFM).toHaveBeenCalledWith(findContent().element.parentElement);
  });

  it.each`
    internal | rendered
    ${true}  | ${true}
    ${false} | ${false}
  `(
    'when internal is $internal, the internal note badge is rendered: $rendered',
    ({ internal, rendered }) => {
      createComponent({ internal });

      expect(findInternalNoteBadge().exists()).toBe(rendered);
    },
  );

  it.each`
    type                | extra
    ${'new diff draft'} | ${{ file_path: 'index.js', file_hash: 'abc', position: { line_range: lineRange } }}
    ${'thread reply'}   | ${{ discussion_id: '1' }}
    ${'new comment'}    | ${{}}
  `('renders the edit and delete buttons for a $type', ({ extra }) => {
    setDiscussion();
    createComponent(extra);

    expect(findEditButton().exists()).toBe(true);
    expect(findDeleteButton().exists()).toBe(true);
  });

  it('does not render the edit and delete buttons when the user cannot edit the draft', () => {
    createComponent({ current_user: { can_edit: false } });

    expect(findEditButton().exists()).toBe(false);
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('editing', () => {
    it('replaces the note body with the note form', async () => {
      await startEditing();

      expect(findNoteForm().props()).toMatchObject({
        noteBody: draft.note,
        noteId: draft.id,
        isDraft: true,
      });
      expect(findContent().isVisible()).toBe(false);
    });

    it('disables the edit and delete buttons while editing', async () => {
      await startEditing();

      expect(findEditButton().props('disabled')).toBe(true);
      expect(findDeleteButton().props('disabled')).toBe(true);
    });

    it('updates the draft, closes the form and focuses the edit button on save', async () => {
      await startEditing();

      findNoteForm().vm.$emit('handle-form-update', 'new text', null, jest.fn(), true);
      await waitForPromises();

      expect(useBatchComments().updateDraft).toHaveBeenCalledWith({
        note: draft,
        noteText: 'new text',
        resolveDiscussion: true,
      });
      expect(findNoteForm().exists()).toBe(false);
      expect(document.activeElement).toBe(findEditButton().element);
    });

    it('shows an alert and keeps the form open when the save fails', async () => {
      const callback = jest.fn();
      await startEditing();
      const error = new Error();
      useBatchComments().updateDraft.mockRejectedValue(error);

      findNoteForm().vm.$emit('handle-form-update', 'new text', null, callback, false);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({ parent: wrapper.element, captureError: true, error }),
      );
      expect(callback).toHaveBeenCalled();
      expect(findNoteForm().exists()).toBe(true);
    });

    it.each`
      isDirty  | confirmed | formOpen
      ${false} | ${false}  | ${false}
      ${true}  | ${true}   | ${false}
      ${true}  | ${false}  | ${true}
    `(
      'when isDirty is $isDirty and confirmed is $confirmed, the form is open: $formOpen',
      async ({ isDirty, confirmed, formOpen }) => {
        confirmAction.mockResolvedValue(confirmed);
        await startEditing();

        findNoteForm().vm.$emit('cancel-form', true, isDirty);
        await waitForPromises();

        expect(confirmAction).toHaveBeenCalledTimes(isDirty ? 1 : 0);
        expect(findNoteForm().exists()).toBe(formOpen);
      },
    );
  });

  it.each([true, false])('when delete confirmed is %s', async (confirmed) => {
    confirmAction.mockResolvedValue(confirmed);
    createComponent();

    findDeleteButton().vm.$emit('click');
    await waitForPromises();

    expect(useBatchComments().deleteDraft.mock.calls).toEqual(confirmed ? [[draft]] : []);
  });

  it('renders the file path and line range for a new diff draft', () => {
    createComponent({
      file_path: 'index.js',
      file_hash: 'abc',
      position: { line_range: lineRange },
    });

    expect(findTitle().text()).toBe('index.js');
    expect(findLineRangeHeadline().props('lineRange')).toBe(lineRange);
  });

  it('renders the image position for an image diff draft', () => {
    createComponent({
      file_path: 'image.png',
      file_hash: 'abc',
      position: { position_type: 'image', x: 10, y: 20 },
    });

    expect(wrapper.findByTestId('preview-item-image-position').text()).toBe(
      'Comment on image at 10x 20y',
    );
    expect(findLineRangeHeadline().exists()).toBe(false);
  });

  it('renders the file path and line range of the discussion for a reply to a diff thread', () => {
    setDiscussion({
      diff_discussion: true,
      diff_file: { file_path: 'thread.js' },
      position: { line_range: lineRange },
    });
    createComponent({ discussion_id: '1' });

    expect(findTitle().text()).toBe('thread.js');
    expect(findLineRangeHeadline().props('lineRange')).toBe(lineRange);
  });

  it('renders the thread title and resolved text for a reply to a thread', () => {
    setDiscussion();
    createComponent({ discussion_id: '1', resolve_discussion: true });

    expect(findTitle().text()).toBe("Reply to Author 'Nick' Name's thread");
    expect(findDraftResolution().text()).toContain('Thread will be resolved');
  });

  it.each`
    type                | extra
    ${'new diff draft'} | ${{ file_path: 'index.js', file_hash: 'abc', position: { line_range: lineRange } }}
    ${'thread reply'}   | ${{ discussion_id: '1' }}
  `('emits click with the draft when the header of a $type is clicked', ({ extra }) => {
    setDiscussion();
    createComponent(extra);

    findHeaderButton().trigger('click');

    expect(wrapper.emitted('click')).toEqual([[draft]]);
  });

  it('renders a direct comment lead instead of a header link for a new comment', () => {
    createComponent();

    expect(findHeaderButton().exists()).toBe(false);
    expect(findTitle().text()).toBe('Direct comment');
  });
});
