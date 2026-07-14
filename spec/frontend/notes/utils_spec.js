import { sprintf } from '~/locale';
import {
  updateNoteErrorMessage,
  isSlashCommand,
  getNoteFormErrorMessages,
  shouldRenderAsDuoSystemNote,
  findStartedNoteForReply,
} from '~/notes/utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { COMMENT_FORM, UPDATE_COMMENT_FORM } from '~/notes/i18n';

describe('note utils', () => {
  describe('updateNoteErrorMessage', () => {
    describe('with server error', () => {
      it('returns error message with server error', () => {
        const error = 'error 1 and error 2';
        const errorMessage = updateNoteErrorMessage({ response: { data: { errors: error } } });

        expect(errorMessage).toEqual(sprintf(UPDATE_COMMENT_FORM.error, { reason: error }));
      });
    });

    describe('without server error', () => {
      it('returns generic error message', () => {
        const errorMessage = updateNoteErrorMessage(null);

        expect(errorMessage).toEqual(UPDATE_COMMENT_FORM.defaultError);
      });
    });
  });

  describe('getNoteFormErrorMessages', () => {
    it('returns quick actions error messages when present', () => {
      const response = {
        status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
        data: {
          quick_actions_status: {
            error_messages: ['Error 1', 'Error 2'],
          },
        },
      };

      expect(getNoteFormErrorMessages(response)).toEqual(['Error 1', 'Error 2']);
    });

    it('returns formatted error when errors field exists', () => {
      const response = {
        status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
        data: {
          errors: 'Something went wrong',
        },
      };

      expect(getNoteFormErrorMessages(response)).toEqual([
        sprintf(COMMENT_FORM.error, { reason: 'something went wrong' }),
      ]);
    });

    it('returns default error for non-422 status', () => {
      const response = {
        status: HTTP_STATUS_BAD_REQUEST,
        data: { errors: 'Some error' },
      };

      expect(getNoteFormErrorMessages(response)).toEqual([
        COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK,
      ]);
    });

    it('uses custom messages when provided', () => {
      const response = {
        status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
        data: { errors: 'Custom error' },
      };
      const messages = {
        error: 'Custom: %{reason}',
        defaultError: 'Custom default',
      };

      expect(getNoteFormErrorMessages(response, messages)).toEqual([
        sprintf('Custom: %{reason}', { reason: 'custom error' }),
      ]);
    });

    it('returns custom default error when no response', () => {
      const messages = { defaultError: 'Custom default error' };

      expect(getNoteFormErrorMessages(null, messages)).toEqual(['Custom default error']);
    });

    it('returns default error when response is null', () => {
      expect(getNoteFormErrorMessages(null)).toEqual([COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK]);
    });
  });

  describe('isSlashCommand', () => {
    it.each`
      message                              | shouldBeSlashCommand
      ${'/close'}                          | ${true}
      ${'/label ~bug'}                     | ${true}
      ${'/assign @user'}                   | ${true}
      ${'This is not a slash command'}     | ${false}
      ${'Messsage with a / in the middle'} | ${false}
      ${' /not-a-command'}                 | ${false}
      ${'\n\n/command'}                    | ${true}
      ${''}                                | ${false}
      ${null}                              | ${false}
      ${undefined}                         | ${false}
    `(
      'when passed `$message` as a message parameter it returns `$shouldBeSlashCommand`',
      ({ message, shouldBeSlashCommand } = {}) => {
        expect(isSlashCommand(message)).toBe(shouldBeSlashCommand);
      },
    );
  });

  describe('shouldRenderAsDuoSystemNote', () => {
    it.each`
      description                                      | note                                                                                                     | expected
      ${'duo mention note (duo_session_status set)'}   | ${{ system: true, duo_session_status: 'running', author: {} }}                                           | ${true}
      ${'duo mention note (duo_session_status null)'}  | ${{ system: true, duo_session_status: null, author: {} }}                                                | ${true}
      ${'duo mention note despite comment-dots icon'}  | ${{ system: true, duo_session_status: 'running', system_note_icon_name: 'comment-dots', author: {} }}    | ${true}
      ${'duo code review progress note (bot author)'}  | ${{ system: true, author: { user_type: 'duo_code_review_bot' } }}                                        | ${true}
      ${'duo bot cross-reference note (comment-dots)'} | ${{ system: true, system_note_icon_name: 'comment-dots', author: { user_type: 'duo_code_review_bot' } }} | ${false}
      ${'plain system note'}                           | ${{ system: true, author: { user_type: 'human' } }}                                                      | ${false}
      ${'non-system note with duo_session_status'}     | ${{ system: false, duo_session_status: 'running', author: {} }}                                          | ${false}
      ${'undefined note'}                              | ${undefined}                                                                                             | ${false}
    `('returns $expected for $description', ({ note, expected }) => {
      expect(shouldRenderAsDuoSystemNote(note)).toBe(expected);
    });
  });

  describe('findStartedNoteForReply', () => {
    const startedNote = {
      id: 'started-1',
      system: true,
      duo_session_status: 'running',
      discussion_id: 'disc-1',
      author: { id: 101 },
    };
    const replyNote = {
      id: 'reply-1',
      system: false,
      discussion_id: 'disc-1',
      author: { id: 101 },
    };
    const discussions = [{ id: 'disc-1', notes: [startedNote] }];

    it('returns the started note when a reply and a matching started note share a discussion', () => {
      expect(findStartedNoteForReply([replyNote], discussions)).toBe(startedNote);
    });

    it('returns the started note when duo_session_status is null (key present but null)', () => {
      const startedNoteNullStatus = { ...startedNote, duo_session_status: null };
      const discussionsWithNull = [{ id: 'disc-1', notes: [startedNoteNullStatus] }];

      expect(findStartedNoteForReply([replyNote], discussionsWithNull)).toBe(startedNoteNullStatus);
    });

    it('returns the Duo Code Review chat progress note (duo_code_review_bot system note, no duo_session_status)', () => {
      const progressNote = {
        id: 'progress-1',
        system: true,
        author: { id: 999, user_type: 'duo_code_review_bot' },
        discussion_id: 'disc-1',
      };
      const botReply = {
        id: 'bot-reply-1',
        system: false,
        author: { id: 999, user_type: 'duo_code_review_bot' },
        discussion_id: 'disc-1',
      };
      const discussionsWithProgress = [{ id: 'disc-1', notes: [progressNote] }];

      expect(findStartedNoteForReply([botReply], discussionsWithProgress)).toBe(progressNote);
    });

    it('does not remove the started note when a human reply arrives in the same discussion', () => {
      const humanReply = {
        id: 'human-reply-1',
        system: false,
        discussion_id: 'disc-1',
        author: { id: 7, user_type: 'human' },
      };

      expect(findStartedNoteForReply([humanReply], discussions)).toBeNull();
    });

    it('returns null when only ordinary (non-Duo) comments arrive — does not treat every non-system note as a Duo reply', () => {
      const ordinaryNote = { id: 'ordinary-1', system: false, discussion_id: 'disc-1' };
      const discussionsWithoutStarted = [
        { id: 'disc-1', notes: [{ id: 'plain-system', system: true }] },
      ];

      expect(findStartedNoteForReply([ordinaryNote], discussionsWithoutStarted)).toBeNull();
    });

    it('returns null when no started note is present in the discussion', () => {
      const discussionsWithoutStarted = [{ id: 'disc-1', notes: [{ id: 'other', system: true }] }];

      expect(findStartedNoteForReply([replyNote], discussionsWithoutStarted)).toBeNull();
    });

    it('returns null when the incoming notes list is empty', () => {
      expect(findStartedNoteForReply([], discussions)).toBeNull();
    });

    it('returns null when an author-less reply lands in an unloaded discussion', () => {
      const noteInOtherDiscussion = { id: 'reply-2', system: false, discussion_id: 'disc-99' };

      expect(findStartedNoteForReply([noteInOtherDiscussion], discussions)).toBeNull();
    });

    it('returns the standalone started note when a same-author reply lands in an unloaded discussion (Duo Code Review path)', () => {
      const progressNote = {
        id: 'progress-1',
        system: true,
        author: { id: 999, user_type: 'duo_code_review_bot' },
        discussion_id: 'disc-1',
      };
      // Review output lands in a brand-new diff discussion not yet loaded on the
      // frontend, so the reply's discussion_id matches no loaded discussion.
      const botReply = {
        id: 'bot-reply-1',
        system: false,
        author: { id: 999, user_type: 'duo_code_review_bot' },
        discussion_id: 'disc-unloaded',
      };
      const discussionsWithProgress = [{ id: 'disc-1', notes: [progressNote] }];

      expect(findStartedNoteForReply([botReply], discussionsWithProgress)).toBe(progressNote);
    });

    it('returns null when a same-author reply lands in an unloaded discussion with no started note loaded', () => {
      // The progress note has already been removed from frontend state, so the
      // fallback scan across all discussions must not produce a false positive.
      const botReply = {
        id: 'bot-reply-2',
        system: false,
        author: { id: 999, user_type: 'duo_code_review_bot' },
        discussion_id: 'disc-unloaded',
      };
      const discussionsWithoutProgress = [{ id: 'disc-1', notes: [{ id: 'plain', system: true }] }];

      expect(findStartedNoteForReply([botReply], discussionsWithoutProgress)).toBeNull();
    });

    it('does not remove the started note when a human reply lands in an unloaded discussion', () => {
      const humanReply = {
        id: 'human-reply-2',
        system: false,
        discussion_id: 'disc-unloaded',
        author: { id: 7, user_type: 'human' },
      };

      expect(findStartedNoteForReply([humanReply], discussions)).toBeNull();
    });

    it('ignores system notes in the incoming batch when searching for a reply', () => {
      const incomingSystemNote = { id: 'sys-1', system: true, discussion_id: 'disc-1' };

      expect(findStartedNoteForReply([incomingSystemNote], discussions)).toBeNull();
    });
  });
});
