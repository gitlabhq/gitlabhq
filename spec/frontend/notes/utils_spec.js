import { sprintf } from '~/locale';
import { getErrorMessages } from '~/notes/utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY, HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import { COMMENT_FORM } from '~/notes/i18n';

describe('getErrorMessages', () => {
  describe('when http status is not HTTP_STATUS_UNPROCESSABLE_ENTITY', () => {
    it('returns generic error', () => {
      const errorMessages = getErrorMessages(
        { errors: ['unknown error'] },
        HTTP_STATUS_BAD_REQUEST,
      );

      expect(errorMessages).toStrictEqual([COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK]);
    });
  });

  describe('when http status is HTTP_STATUS_UNPROCESSABLE_ENTITY', () => {
    it('returns all errors', () => {
      const errorMessages = getErrorMessages(
        { errors: 'error 1 and error 2' },
        HTTP_STATUS_UNPROCESSABLE_ENTITY,
      );

      expect(errorMessages).toStrictEqual([
        sprintf(COMMENT_FORM.error, { reason: 'error 1 and error 2' }),
      ]);
    });

    describe('when response contains commands_only errors', () => {
      it('only returns commands_only errors', () => {
        const errorMessages = getErrorMessages(
          {
            errors: {
              commands_only: ['commands_only error 1', 'commands_only error 2'],
              base: ['base error 1'],
            },
          },
          HTTP_STATUS_UNPROCESSABLE_ENTITY,
        );

        expect(errorMessages).toStrictEqual(['commands_only error 1', 'commands_only error 2']);
      });
    });
  });
});
