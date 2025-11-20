import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import NoteableNote from '~/rapid_diffs/app/discussions/noteable_note.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import NoteActions from '~/notes/components/note_actions.vue';
import NoteBody from '~/notes/components/note_body.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';
import {
  HTTP_STATUS_GONE,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import axios from 'helpers/mocks/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/alert');
jest.mock('~/lib/utils/secret_detection');

describe('NoteableNote', () => {
  let wrapper;
  let defaultProps;
  let mockAdapter;

  const defaultProvisions = {
    endpoints: {
      reportAbuse: '/report-abuse',
    },
  };

  const createNote = (customOptions) => {
    return merge(
      {
        id: '1',
        author: {
          id: 100,
          name: 'name',
          path: 'path',
          username: 'username',
          avatar_url: 'avatar_url',
        },
        current_user: {
          can_award_emoji: true,
          can_edit: true,
        },
        internal: false,
        imported: false,
        is_contributor: true,
        is_noteable_author: true,
        created_at: '2025-08-25T05:03:12.757Z',
        noteable_note_url: '/noteable_note_url',
        human_access: 'Developer',
        project_name: 'project_name',
        noteable_type: 'Commit',
        path: '/note/path',
        noteable_id: 123,
        isEditing: false,
      },
      customOptions,
    );
  };

  const createComponent = (props = {}, provide = defaultProvisions) => {
    wrapper = shallowMount(NoteableNote, {
      propsData: merge(defaultProps, props),
      provide,
    });
  };

  beforeEach(() => {
    mockAdapter = new MockAdapter(axios);
    defaultProps = {
      note: createNote(),
    };
    confirmAction.mockResolvedValue(true);
    detectAndConfirmSensitiveTokens.mockResolvedValue(true);
  });

  afterEach(() => {
    mockAdapter.restore();
    confirmAction.mockClear();
    createAlert.mockClear();
    detectAndConfirmSensitiveTokens.mockClear();
  });

  const findNoteActions = () => wrapper.findComponent(NoteActions);
  const findNoteBody = () => wrapper.findComponent(NoteBody);

  it('shows avatar with link', () => {
    createComponent();
    expect(wrapper.findComponent(GlAvatarLink).attributes()).toMatchObject({
      href: defaultProps.note.author.path,
      'data-user-id': defaultProps.note.author.id.toString(),
      'data-username': defaultProps.note.author.username,
    });
    expect(wrapper.findComponent(GlAvatar).props()).toMatchObject({
      src: defaultProps.note.author.avatar_url,
      entityName: defaultProps.note.author.username,
      alt: defaultProps.note.author.name,
      size: 24,
    });
  });

  it('shows note header with correct props', () => {
    createComponent();
    expect(wrapper.findComponent(NoteHeader).props()).toMatchObject({
      author: defaultProps.note.author,
      createdAt: defaultProps.note.created_at,
      noteId: defaultProps.note.id,
      isInternalNote: defaultProps.note.internal,
      isImported: defaultProps.note.imported,
    });
  });

  it('shows note actions with correct props', () => {
    createComponent({ showReplyButton: true });
    expect(findNoteActions().props()).toMatchObject({
      author: defaultProps.note.author,
      authorId: defaultProps.note.author.id,
      noteId: defaultProps.note.id,
      noteUrl: defaultProps.note.noteable_note_url,
      accessLevel: defaultProps.note.human_access,
      isContributor: defaultProps.note.is_contributor,
      isAuthor: defaultProps.note.is_noteable_author,
      projectName: defaultProps.note.project_name,
      noteableType: defaultProps.note.noteable_type,
      showReply: true,
      canEdit: defaultProps.note.current_user.can_edit,
      canAwardEmoji: defaultProps.note.current_user.can_award_emoji,
      canDelete: defaultProps.note.current_user.can_edit,
      canReportAsAbuse: true,
    });
  });

  it('shows note body with correct props', () => {
    createComponent({ autosaveKey: 'autosave-key', restoreFromAutosave: true });
    expect(findNoteBody().props()).toMatchObject({
      note: defaultProps.note,
      canEdit: defaultProps.note.current_user.can_edit,
      isEditing: defaultProps.note.isEditing,
      autosaveKey: 'autosave-key',
      restoreFromAutosave: true,
    });
  });

  describe('note deletion', () => {
    it('confirms deletion, sends DELETE request, and emits noteDeleted on success', async () => {
      mockAdapter.onDelete(defaultProps.note.path).reply(HTTP_STATUS_OK);

      createComponent();
      findNoteActions().vm.$emit('delete');

      expect(confirmAction).toHaveBeenCalledWith(
        'Are you sure you want to delete this comment?',
        expect.objectContaining({ primaryBtnText: 'Delete comment' }),
      );

      await axios.waitForAll();

      expect(wrapper.emitted('noteDeleted')).toStrictEqual([[]]);
    });

    it('does not send request or emit if confirmation is cancelled', async () => {
      confirmAction.mockResolvedValueOnce(false);
      mockAdapter.onDelete(defaultProps.note.path).reply(HTTP_STATUS_OK);

      createComponent();
      findNoteActions().vm.$emit('delete');

      await axios.waitForAll();

      expect(wrapper.emitted('noteDeleted')).toBeUndefined();
    });

    it('creates alert on deletion failure', async () => {
      mockAdapter.onDelete(defaultProps.note.path).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();
      findNoteActions().vm.$emit('delete');

      await axios.waitForAll();

      expect(createAlert).toHaveBeenCalled();
      expect(wrapper.emitted('noteDeleted')).toBeUndefined();
    });
  });

  // TODO: enable when NoteBody is migrated
  // eslint-disable-next-line jest/no-disabled-tests
  describe.skip('note editing/saving via NoteBody', () => {
    const noteText = 'updated note content';

    it('scrolls element into view when editing', async () => {
      const spy = jest.spyOn(Element.prototype, 'scrollIntoView');
      createComponent({ note: createNote({ isEditing: true }) });
      await nextTick();
      expect(spy).toHaveBeenCalled();
    });

    it('sends PUT request and emits noteUpdated on NoteBody save-note call', async () => {
      const updatedNote = createNote({ body: noteText });
      mockAdapter.onPut(defaultProps.note.path).reply(HTTP_STATUS_OK, { note: updatedNote });

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().props('saveNote')({ noteText });

      expect(detectAndConfirmSensitiveTokens).toHaveBeenCalledWith({ content: noteText });

      await axios.waitForAll();

      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[]]);
      expect(wrapper.emitted('noteUpdated')).toStrictEqual([[updatedNote]]);
    });

    it('emits noteDeleted if server returns HTTP_STATUS_GONE', async () => {
      mockAdapter.onPut(defaultProps.note.path).reply(HTTP_STATUS_GONE);

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().props('saveNote')({ noteText });

      await axios.waitForAll();

      expect(wrapper.emitted('noteDeleted')).toStrictEqual([[]]);
      expect(wrapper.emitted('noteUpdated')).toBeUndefined();
    });

    it('creates alert on other API failure', async () => {
      mockAdapter.onPut(defaultProps.note.path).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().props('saveNote')({ noteText });

      await axios.waitForAll();

      expect(createAlert).toHaveBeenCalled();
      expect(wrapper.emitted('noteUpdated')).toBeUndefined();
    });
  });

  describe('cancel editing via NoteBody', () => {
    it('emits cancelEditing when confirmation is not needed', async () => {
      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().vm.$emit('cancelEditing', { shouldConfirm: false, isDirty: false });

      await nextTick();

      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[]]);
    });

    it('shows confirmation modal when dirty and confirms, then emits cancelEditing', async () => {
      confirmAction.mockResolvedValueOnce(true);

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().vm.$emit('cancelEditing', { shouldConfirm: true, isDirty: true });

      expect(confirmAction).toHaveBeenCalledWith(
        'Are you sure you want to cancel editing this comment?',
        expect.objectContaining({ primaryBtnText: 'Cancel editing' }),
      );

      await waitForPromises();

      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[]]);
    });

    it('does not emit cancelEditing if confirmation is denied', async () => {
      confirmAction.mockResolvedValueOnce(false);

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().vm.$emit('cancelEditing', { shouldConfirm: true, isDirty: true });

      await waitForPromises();

      expect(wrapper.emitted('cancelEditing')).toBeUndefined();
    });
  });
});
