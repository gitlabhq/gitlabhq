import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { clone } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DiffsModule from '~/diffs/store/modules';
import NoteActions from '~/notes/components/note_actions.vue';
import NoteBody from '~/notes/components/note_body.vue';
import NoteHeader from '~/notes/components/note_header.vue';
import issueNote from '~/notes/components/noteable_note.vue';
import NotesModule from '~/notes/stores/modules';
import { NOTEABLE_TYPE_MAPPING } from '~/notes/constants';
import { createAlert } from '~/alert';
import { UPDATE_COMMENT_FORM } from '~/notes/i18n';
import { sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { SHOW_CLIENT_SIDE_SECRET_DETECTION_WARNING } from '~/lib/utils/secret_detection';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { noteableDataMock, notesDataMock, note } from '../mock_data';

Vue.use(Vuex);
jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
confirmAction.mockResolvedValueOnce(false);
const { bindInternalEventDocument } = useMockInternalEventsTracking();

const singleLineNotePosition = {
  line_range: {
    start: {
      line_code: 'abc_1_1',
      type: null,
      old_line: '1',
      new_line: '1',
    },
    end: {
      line_code: 'abc_1_1',
      type: null,
      old_line: '1',
      new_line: '1',
    },
  },
};

describe('issue_note', () => {
  let store;
  let wrapper;

  const REPORT_ABUSE_PATH = '/abuse_reports/add_category';

  const findNoteBody = () => wrapper.findComponent(NoteBody);

  const findMultilineComment = () => wrapper.findByTestId('multiline-comment');

  const createWrapper = (props = {}, storeUpdater = (s) => s) => {
    store = new Vuex.Store(
      storeUpdater({
        modules: {
          notes: NotesModule(),
          diffs: DiffsModule(),
        },
      }),
    );

    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    // the component overwrites the `note` prop with every action, hence create a copy
    const noteCopy = clone(props.note || note);

    wrapper = mountExtended(issueNote, {
      store,
      propsData: {
        note: noteCopy,
        ...props,
      },
      stubs: [
        'note-header',
        'user-avatar-link',
        'note-actions',
        'note-body',
        'multiline-comment-form',
      ],
      provide: {
        reportAbusePath: REPORT_ABUSE_PATH,
      },
    });
  };

  describe('mutiline comments', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render if has multiline comment', async () => {
      const position = {
        line_range: {
          start: {
            line_code: 'abc_1_1',
            type: null,
            old_line: '1',
            new_line: '1',
          },
          end: {
            line_code: 'abc_2_2',
            type: null,
            old_line: '2',
            new_line: '2',
          },
        },
      };
      const line = {
        line_code: 'abc_1_1',
        type: null,
        old_line: '1',
        new_line: '1',
      };
      wrapper.setProps({
        note: { ...note, position },
        discussionRoot: true,
        line,
      });

      await nextTick();
      expect(findMultilineComment().text()).toBe('Comment on lines 1 to 2');
    });

    it('should only render if it has everything it needs', async () => {
      const position = {
        line_range: {
          start: {
            line_code: 'abc_1_1',
            type: null,
            old_line: '',
            new_line: '',
          },
          end: {
            line_code: 'abc_2_2',
            type: null,
            old_line: '2',
            new_line: '2',
          },
        },
      };
      const line = {
        line_code: 'abc_1_1',
        type: null,
        old_line: '1',
        new_line: '1',
      };
      wrapper.setProps({
        note: { ...note, position },
        discussionRoot: true,
        line,
      });

      await nextTick();
      expect(findMultilineComment().exists()).toBe(false);
    });

    it('should not render if has single line comment', async () => {
      const position = {
        line_range: {
          start: {
            line_code: 'abc_1_1',
            type: null,
            old_line: '1',
            new_line: '1',
          },
          end: {
            line_code: 'abc_1_1',
            type: null,
            old_line: '1',
            new_line: '1',
          },
        },
      };
      const line = {
        line_code: 'abc_1_1',
        type: null,
        old_line: '1',
        new_line: '1',
      };
      wrapper.setProps({
        note: { ...note, position },
        discussionRoot: true,
        line,
      });

      await nextTick();
      expect(findMultilineComment().exists()).toBe(false);
    });

    it('should not render if `line_range` is unavailable', () => {
      expect(findMultilineComment().exists()).toBe(false);
    });
  });

  describe('rendering', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('avatar sizes in diffs', () => {
      const line = {
        line_code: 'abc_1_1',
        type: null,
        old_line: '1',
        new_line: '1',
      };

      it('should render 24px avatars', async () => {
        wrapper.setProps({
          note: { ...note },
          discussionRoot: true,
          line,
        });

        await nextTick();

        const avatar = wrapper.findComponent(GlAvatar);
        const avatarProps = avatar.props();
        expect(avatarProps.size).toBe(24);
      });
    });

    it('should render user avatar link with popover support', () => {
      const { author } = note;
      const avatarLink = wrapper.findComponent(GlAvatarLink);

      expect(avatarLink.classes()).toContain('js-user-link');
      expect(avatarLink.attributes()).toMatchObject({
        href: author.path,
        'data-user-id': `${author.id}`,
        'data-username': `${author.username}`,
      });
    });

    it('should render user avatar', () => {
      const { author } = note;
      const avatar = wrapper.findComponent(GlAvatar);
      const avatarProps = avatar.props();

      expect(avatarProps.src).toBe(author.avatar_url);
      expect(avatarProps.entityName).toBe(author.username);
      expect(avatarProps.alt).toBe(author.name);
      expect(avatarProps.size).toEqual(32);
    });

    it('should render note header content', () => {
      const noteHeader = wrapper.findComponent(NoteHeader);
      const noteHeaderProps = noteHeader.props();

      expect(noteHeaderProps.author).toBe(note.author);
      expect(noteHeaderProps.createdAt).toBe(note.created_at);
      expect(noteHeaderProps.noteId).toBe(note.id);
      expect(noteHeaderProps.noteableType).toBe(NOTEABLE_TYPE_MAPPING[note.noteable_type]);
      expect(noteHeaderProps.isImported).toBe(note.imported);
    });

    it('should render note actions', () => {
      const { author } = note;
      const noteActions = wrapper.findComponent(NoteActions);
      const noteActionsProps = noteActions.props();

      expect(noteActionsProps.authorId).toBe(author.id);
      expect(noteActionsProps.noteId).toBe(note.id);
      expect(noteActionsProps.noteUrl).toBe(note.noteable_note_url);
      expect(noteActionsProps.accessLevel).toBe(note.human_access);
      expect(noteActionsProps.canEdit).toBe(note.current_user.can_edit);
      expect(noteActionsProps.canAwardEmoji).toBe(note.current_user.can_award_emoji);
      expect(noteActionsProps.canDelete).toBe(note.current_user.can_edit);
      expect(noteActionsProps.canReportAsAbuse).toBe(true);
      expect(noteActionsProps.canResolve).toBe(false);
      expect(noteActionsProps.resolvable).toBe(false);
      expect(noteActionsProps.isResolved).toBe(false);
      expect(noteActionsProps.isResolving).toBe(false);
      expect(noteActionsProps.resolvedBy).toEqual({});
    });

    it('should render issue body', () => {
      expect(findNoteBody().props().note).toMatchObject(note);
      expect(findNoteBody().props().line).toBe(null);
      expect(findNoteBody().props().canEdit).toBe(note.current_user.can_edit);
      expect(findNoteBody().props().isEditing).toBe(false);
      expect(findNoteBody().props().helpPagePath).toBe('');
    });

    it('prevents note preview xss', async () => {
      const noteBody =
        '<img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" onload="alert(1)" />';
      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {});

      store.hotUpdate({
        modules: {
          notes: {
            actions: {
              updateNote() {},
              setSelectedCommentPositionHover() {},
            },
          },
        },
      });

      findNoteBody().vm.$emit('handleFormUpdate', {
        noteText: noteBody,
        parentElement: null,
        callback: () => {},
      });

      await waitForPromises();
      expect(alertSpy).not.toHaveBeenCalled();
      expect(findNoteBody().props().note.note_html).toBe(
        '<img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">',
      );
    });
  });

  describe('internal note', () => {
    it('has internal note class for internal notes', () => {
      createWrapper({ note: { ...note, internal: true } });

      expect(wrapper.classes()).toContain('internal-note');
    });

    it('does not have internal note class for external notes', () => {
      createWrapper();

      expect(wrapper.classes()).not.toContain('internal-note');
    });
  });

  describe('formUpdateHandler', () => {
    const updateNote = jest.fn();
    const params = {
      noteText: 'updated note text',
      parentElement: null,
      callback: jest.fn(),
      resolveDiscussion: false,
    };

    const updateActions = () => {
      store.hotUpdate({
        modules: {
          notes: {
            actions: {
              updateNote,
              setSelectedCommentPositionHover() {},
            },
          },
        },
      });
    };

    beforeEach(() => {
      createWrapper();
      updateActions();
    });

    afterEach(() => updateNote.mockReset());

    it('emits handleUpdateNote', async () => {
      const updatedNote = { ...note, note_html: `<p dir="auto">${params.noteText}</p>\n` };

      findNoteBody().vm.$emit('handleFormUpdate', params);
      await nextTick();
      await waitForPromises();

      expect(wrapper.emitted('handleUpdateNote')).toHaveLength(1);

      expect(wrapper.emitted('handleUpdateNote')[0]).toEqual([
        {
          note: updatedNote,
          noteText: params.noteText,
          resolveDiscussion: params.resolveDiscussion,
          flashContainer: wrapper.vm.$el,
          callback: expect.any(Function),
          errorCallback: expect.any(Function),
        },
      ]);
    });

    it('updates note content', async () => {
      findNoteBody().vm.$emit('handleFormUpdate', params);

      await nextTick();
      await waitForPromises();

      expect(findNoteBody().props().note.note_html).toBe(`<p dir="auto">${params.noteText}</p>\n`);
      expect(findNoteBody().props('isEditing')).toBe(false);
    });

    it('should not update note with sensitive token', async () => {
      const { trackEventSpy } = bindInternalEventDocument();

      const sensitiveMessage = 'token: glpat-1234567890abcdefghij';

      // Ensure initial note content is as expected
      expect(findNoteBody().props().note.note_html).toBe(note.note_html);

      // Attempt to update note with sensitive content
      const updatedNote = { ...params, noteText: sensitiveMessage };
      findNoteBody().vm.$emit('handleFormUpdate', updatedNote);

      await nextTick();
      await waitForPromises();

      // Expect note content to remain unchanged
      expect(findNoteBody().props().note.note_html).toBe(note.note_html);
      expect(confirmAction).toHaveBeenCalledWith(
        '',
        expect.objectContaining({ title: 'Warning: Potential secret detected' }),
      );
      expect(trackEventSpy).toHaveBeenCalledWith(SHOW_CLIENT_SIDE_SECRET_DETECTION_WARNING, {
        label: 'comment',
        property: 'GitLab personal access token',
        value: 0,
      });
    });

    describe('when updateNote returns errors', () => {
      beforeEach(() => {
        updateNote.mockRejectedValue({
          response: {
            status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
            data: { errors: 'error 1 and error 2' },
          },
        });
      });

      beforeEach(() => {
        findNoteBody().vm.$emit('handleFormUpdate', { ...params, noteText: 'invalid note' });
      });

      it('renders error message and restores content of updated note', async () => {
        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({
          message: sprintf(UPDATE_COMMENT_FORM.error, { reason: 'error 1 and error 2' }, false),
          parent: wrapper.vm.$el,
        });

        expect(findNoteBody().props('isEditing')).toBe(true);
        expect(findNoteBody().props().note.note_html).toBe(note.note_html);
      });
    });
  });

  describe('diffFile', () => {
    it.each`
      scenario                         | files        | noteDef
      ${'the note has no position'}    | ${undefined} | ${note}
      ${'the Diffs store has no data'} | ${[]}        | ${{ ...note, position: singleLineNotePosition }}
    `(
      'returns `null` when $scenario and no diff file is provided as a prop',
      ({ noteDef, diffs }) => {
        const storeUpdater = (rawStore) => {
          const updatedStore = { ...rawStore };

          if (diffs) {
            updatedStore.modules.diffs.state.diffFiles = diffs;
          }

          return updatedStore;
        };

        createWrapper({ note: noteDef, discussionFile: null }, storeUpdater);

        expect(findNoteBody().props().file).toBe(null);
      },
    );

    it("returns the correct diff file from the Diffs store if it's available", () => {
      createWrapper(
        {
          note: { ...note, position: singleLineNotePosition },
        },
        (rawStore) => {
          const updatedStore = { ...rawStore };
          updatedStore.modules.diffs.state.diffFiles = [
            { file_hash: 'abc', testId: 'diffFileTest' },
          ];
          return updatedStore;
        },
      );

      expect(findNoteBody().props().file.testId).toBe('diffFileTest');
    });

    it('returns the provided diff file if the more robust getters fail', () => {
      createWrapper(
        {
          note: { ...note, position: singleLineNotePosition },
          discussionFile: { testId: 'diffFileTest' },
        },
        (rawStore) => {
          const updatedStore = { ...rawStore };
          updatedStore.modules.diffs.state.diffFiles = [];
          return updatedStore;
        },
      );

      expect(findNoteBody().props().file.testId).toBe('diffFileTest');
    });
  });

  describe('editing', () => {
    it('respects isEditing prop on the note', () => {
      createWrapper({
        note: { ...note, isEditing: true },
      });
      expect(findNoteBody().props('isEditing')).toBe(true);
    });

    it('passes down restoreFromAutosave', () => {
      createWrapper({
        note: { ...note },
        restoreFromAutosave: true,
      });
      expect(findNoteBody().props('restoreFromAutosave')).toBe(true);
    });

    it('passes down autosaveKey', () => {
      const autosaveKey = 'autosave';
      createWrapper({
        note: { ...note },
        autosaveKey,
      });
      expect(findNoteBody().props('autosaveKey')).toBe(autosaveKey);
    });
  });
});
