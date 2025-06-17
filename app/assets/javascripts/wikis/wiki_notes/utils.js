import { COMMENT_FORM } from '~/notes/i18n';
import { sprintf, __ } from '~/locale';
import { parseGid, isGid } from '~/graphql_shared/utils';

export const createNoteErrorMessages = (err) => {
  // TODO: make error message more specific
  if (err?.graphQLErrors?.length || err?.clientErrors) {
    return [
      sprintf(
        COMMENT_FORM.error,
        {
          reason: __(
            'An unexpected error occurred trying to submit your comment. Please try again.',
          ),
        },
        false,
      ),
    ];
  }

  return [COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK];
};

export const getIdFromGid = (val) => (isGid(val) ? parseGid(val).id : val);

export const getAutosaveKey = (noteableType, noteId) => `Note/${noteableType}/${noteId}`;
