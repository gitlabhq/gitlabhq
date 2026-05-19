import { merge } from 'lodash-es';
import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NoteableNote from '~/rapid_diffs/app/discussions/noteable_note.vue';
import NoteHeader from '~/rapid_diffs/app/discussions/note_header.vue';
import NoteActions from '~/rapid_diffs/app/discussions/note_actions.vue';
import NoteBody from '~/rapid_diffs/app/discussions/note_body.vue';
import TimelineEntryItem from '~/rapid_diffs/app/discussions/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { createAlert } from '~/alert';

import { UPDATE_COMMENT_FORM } from '~/notes/i18n';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/alert');
jest.mock('~/lib/utils/secret_detection');

describe('NoteableNote', () => {
  let wrapper;
  let defaultProps;
  let store;

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
        toggle_award_path: '/award',
      },
      customOptions,
    );
  };

  const createComponent = (props = {}, provide = defaultProvisions) => {
    wrapper = shallowMount(NoteableNote, {
      propsData: merge(defaultProps, props),
      provide: { store, ...provide },
      stubs: {
        GlSprintf: {
          template: '<span><slot name="timeago" /><slot name="author" /></span>',
        },
      },
    });
  };

  beforeEach(() => {
    defaultProps = {
      note: createNote(),
    };
    store = {
      saveNote: jest.fn().mockResolvedValue(),
      destroyNote: jest.fn().mockResolvedValue(),
      deleteNote: jest.fn(),
      toggleAwardOnNote: jest.fn().mockResolvedValue(),
    };
    confirmAction.mockResolvedValue(true);
    detectAndConfirmSensitiveTokens.mockResolvedValue(true);
  });

  afterEach(() => {
    confirmAction.mockClear();
    createAlert.mockClear();
    detectAndConfirmSensitiveTokens.mockClear();
  });

  const findNoteActions = () => wrapper.findComponent(NoteActions);
  const findNoteBody = () => wrapper.findComponent(NoteBody);
  const findTimelineEntryItem = () => wrapper.findComponent(TimelineEntryItem);

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
      authorId: defaultProps.note.author.id,
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

  it('propagates note edited event', () => {
    createComponent();
    findNoteBody().vm.$emit('input', 'edit');
    expect(wrapper.emitted('noteEdited')).toStrictEqual([['edit']]);
  });

  describe('TimelineEntryItem', () => {
    it.each`
      prop                  | value        | expected
      ${'timelineLayout'}   | ${true}      | ${true}
      ${'isLastDiscussion'} | ${true}      | ${true}
      ${'timelineLayout'}   | ${undefined} | ${false}
      ${'isLastDiscussion'} | ${undefined} | ${false}
    `('passes $prop as $expected when set to $value', ({ prop, value, expected }) => {
      createComponent(value !== undefined ? { [prop]: value } : {});
      expect(findTimelineEntryItem().props(prop)).toBe(expected);
    });
  });

  describe('note deletion', () => {
    it('confirms deletion and calls store.destroyNote on success', async () => {
      const note = createNote();
      createComponent({ note });
      findNoteActions().vm.$emit('delete');

      expect(confirmAction).toHaveBeenCalledWith(
        'Are you sure you want to delete this comment?',
        expect.objectContaining({ primaryBtnText: 'Delete comment' }),
      );

      await waitForPromises();

      expect(store.destroyNote).toHaveBeenCalledWith(note);
    });

    it('does not call destroyNote if confirmation is cancelled', async () => {
      confirmAction.mockResolvedValueOnce(false);

      createComponent();
      findNoteActions().vm.$emit('delete');

      await waitForPromises();

      expect(store.destroyNote).not.toHaveBeenCalled();
    });

    it('creates alert on deletion failure', async () => {
      store.destroyNote.mockRejectedValue(new Error('fail'));

      createComponent();
      findNoteActions().vm.$emit('delete');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('note editing/saving via NoteBody', () => {
    const noteText = 'updated note content';

    it('scrolls element into view when editing', async () => {
      const spy = jest.spyOn(Element.prototype, 'scrollIntoView');
      createComponent({ note: createNote({ isEditing: true }) });
      await nextTick();
      expect(spy).toHaveBeenCalledWith({ block: 'nearest' });
    });

    it('calls store.saveNote and emits cancelEditing on success', async () => {
      const note = createNote({ isEditing: true });
      createComponent({ note });
      await findNoteBody().props('saveNote')(noteText);

      expect(detectAndConfirmSensitiveTokens).toHaveBeenCalledWith({ content: noteText });
      expect(store.saveNote).toHaveBeenCalledWith(note, noteText);
      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[]]);
    });

    it('shows alert on API failure', async () => {
      store.saveNote.mockRejectedValue(new Error('fail'));

      createComponent({ note: createNote({ isEditing: true }) });
      await findNoteBody().props('saveNote')(noteText);

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: UPDATE_COMMENT_FORM.defaultError,
        }),
      );
    });
  });

  describe('cancel editing via NoteBody', () => {
    it('emits cancelEditing when confirmation is not needed', async () => {
      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().vm.$emit('cancelEditing', false);

      await nextTick();

      expect(wrapper.emitted('cancelEditing')).toStrictEqual([[]]);
    });

    it('shows confirmation modal when needed and confirms, then emits cancelEditing', async () => {
      confirmAction.mockResolvedValueOnce(true);

      createComponent({ note: createNote({ isEditing: true }) });
      findNoteBody().vm.$emit('cancelEditing', true);

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
      findNoteBody().vm.$emit('cancelEditing', true);

      await waitForPromises();

      expect(wrapper.emitted('cancelEditing')).toBeUndefined();
    });
  });

  it('handles award event on note body', async () => {
    const note = createNote();
    const award = 'smile';
    createComponent({ note });
    await wrapper.findComponent(NoteBody).vm.$emit('award', award);
    await waitForPromises();
    expect(store.toggleAwardOnNote).toHaveBeenCalledWith(note, award);
  });

  it('handles award event on note actions', async () => {
    const note = createNote();
    const award = 'smile';
    createComponent({ note });
    await wrapper.findComponent(NoteActions).vm.$emit('award', award);
    await waitForPromises();
    expect(store.toggleAwardOnNote).toHaveBeenCalledWith(note, award);
  });

  describe('resolved note', () => {
    const resolvedBy = {
      id: 200,
      name: 'Jane Doe',
      path: '/jane_doe',
    };
    const resolvedAt = '2025-09-01T10:00:00.000Z';

    const createResolvedNote = (overrides = {}) =>
      createNote({ resolved_at: resolvedAt, resolved_by: resolvedBy, ...overrides });

    it('does not show resolved section when isResolved is false', () => {
      createComponent({ note: createResolvedNote(), isResolved: false });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('shows resolved section when isResolved is true', () => {
      createComponent({ note: createResolvedNote(), isResolved: true });
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });

    it('uses "Resolved" text when not resolved by push', () => {
      createComponent({ note: createResolvedNote({ resolved_by_push: false }), isResolved: true });
      expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
        'Resolved %{timeago} by %{author}',
      );
    });

    it('uses "Automatically resolved" text when resolved by push', () => {
      createComponent({ note: createResolvedNote({ resolved_by_push: true }), isResolved: true });
      expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
        'Automatically resolved %{timeago} by %{author}',
      );
    });

    it('passes resolved_at to TimeAgoTooltip', () => {
      createComponent({ note: createResolvedNote(), isResolved: true });
      expect(wrapper.findComponent(TimeAgoTooltip).props('time')).toBe(resolvedAt);
    });

    it('links to the resolver via GlLink', () => {
      createComponent({ note: createResolvedNote(), isResolved: true });
      const link = wrapper.findComponent(GlLink);
      expect(link.attributes('href')).toBe(resolvedBy.path);
      expect(link.text()).toBe(resolvedBy.name);
    });
  });

  describe('draft notes', () => {
    const createDraftNote = (overrides = {}) => createNote({ isDraft: true, ...overrides });

    it('disables award emoji for draft notes', () => {
      createComponent({ note: createDraftNote() });
      expect(findNoteActions().props('canAwardEmoji')).toBe(false);
    });

    it('disables report as abuse for draft notes', () => {
      createComponent({ note: createDraftNote() });
      expect(findNoteActions().props('canReportAsAbuse')).toBe(false);
    });
  });
});
