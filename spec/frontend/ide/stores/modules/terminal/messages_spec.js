import { escape } from 'lodash';
import { TEST_HOST } from 'spec/test_constants';
import * as messages from '~/ide/stores/modules/terminal/messages';
import { sprintf } from '~/locale';
import httpStatus from '~/lib/utils/http_status';

const TEST_HELP_URL = `${TEST_HOST}/help`;

describe('IDE store terminal messages', () => {
  describe('configCheckError', () => {
    it('returns job error, with status UNPROCESSABLE_ENTITY', () => {
      const result = messages.configCheckError(httpStatus.UNPROCESSABLE_ENTITY, TEST_HELP_URL);

      expect(result).toBe(
        sprintf(
          messages.ERROR_CONFIG,
          {
            helpStart: `<a href="${escape(TEST_HELP_URL)}" target="_blank">`,
            helpEnd: '</a>',
          },
          false,
        ),
      );
    });

    it('returns permission error, with status FORBIDDEN', () => {
      const result = messages.configCheckError(httpStatus.FORBIDDEN, TEST_HELP_URL);

      expect(result).toBe(messages.ERROR_PERMISSION);
    });

    it('returns unexpected error, with unexpected status', () => {
      const result = messages.configCheckError(httpStatus.NOT_FOUND, TEST_HELP_URL);

      expect(result).toBe(messages.UNEXPECTED_ERROR_CONFIG);
    });
  });
});
