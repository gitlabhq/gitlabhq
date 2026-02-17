import { sprintf } from '~/locale';
import {
  createNoteErrorMessages,
  updateNoteErrorMessage,
  isSlashCommand,
  getNoteFormErrorMessages,
} from '~/notes/utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { COMMENT_FORM, UPDATE_COMMENT_FORM } from '~/notes/i18n';

describe('note utils', () => {
  describe('createNoteErrorMessages', () => {
    describe('when http status is not HTTP_STATUS_UNPROCESSABLE_ENTITY', () => {
      it('returns generic error', () => {
        const errorMessages = createNoteErrorMessages(
          { errors: ['unknown error'] },
          HTTP_STATUS_BAD_REQUEST,
        );

        expect(errorMessages).toStrictEqual([COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK]);
      });
    });

    describe('when http status is HTTP_STATUS_UNPROCESSABLE_ENTITY', () => {
      it('returns all errors', () => {
        const errorMessages = createNoteErrorMessages(
          { errors: 'error 1 and error 2' },
          HTTP_STATUS_UNPROCESSABLE_ENTITY,
        );

        expect(errorMessages).toStrictEqual([
          sprintf(COMMENT_FORM.error, { reason: 'error 1 and error 2' }),
        ]);
      });

      describe('when response contains commands_only errors', () => {
        it('only returns commands_only errors', () => {
          const errorMessages = createNoteErrorMessages(
            {
              errors: {
                base: ['base error 1'],
              },
              quick_actions_status: {
                commands_only: true,
                error_messages: ['commands_only error 1', 'commands_only error 2'],
              },
            },
            HTTP_STATUS_UNPROCESSABLE_ENTITY,
          );

          expect(errorMessages).toStrictEqual(['commands_only error 1', 'commands_only error 2']);
        });
      });
    });
  });

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
});
