import {
  createNoteErrorMessages,
  getIdFromGid,
  getAutosaveKey,
} from '~/pages/shared/wikis/wiki_notes/utils';
import { COMMENT_FORM } from '~/notes/i18n';
import { sprintf } from '~/locale';
import * as utils from '~/graphql_shared/utils';

describe('createNoteErrorMessages', () => {
  it('should return the correct error message by default', () => {
    const actualMessage = createNoteErrorMessages()[0];

    const expectedMessage = COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK;

    expect(actualMessage).toBe(expectedMessage);
  });

  it('should return the correct error message when the err is a graphql error', () => {
    const err = {
      graphQLErrors: [{ message: 'GraphQL error' }],
    };
    const actualMessage = createNoteErrorMessages(err)[0];

    const expectedMessage = sprintf(
      COMMENT_FORM.error,
      { reason: 'An unexpected error occurred trying to submit your comment. Please try again.' },
      false,
    );

    expect(actualMessage).toBe(expectedMessage);
  });
});

describe('getIdFromGid', () => {
  afterEach(() => {
    jest.resetAllMocks();
  });

  it.each`
    gid                         | expectedId
    ${'gid://gitlab/User/7'}    | ${'7'}
    ${'gid://gitlab/Project/9'} | ${'9'}
    ${'gid://gitlab/Group/3'}   | ${'3'}
  `('should return the id when the input is a gid', ({ gid, expectedId }) => {
    jest.spyOn(utils, 'isGid').mockReturnValue(true);
    jest.spyOn(utils, 'parseGid').mockReturnValue({ id: expectedId });

    expect(getIdFromGid(gid)).toBe(expectedId);
  });

  it.each`
    value
    ${'7'}
    ${'not id'}
    ${'string'}
  `('should return the input when it is not a gid', ({ value }) => {
    jest.spyOn(utils, 'isGid').mockReturnValue(false);
    expect(getIdFromGid(value)).toBe(value);
  });
});

describe('getAutosaveKey', () => {
  it.each`
    noteableType      | noteId | expectedKey
    ${'Issue'}        | ${'1'} | ${'Note/Issue/1'}
    ${'MergeRequest'} | ${'2'} | ${'Note/MergeRequest/2'}
  `('should return the correct key', ({ noteableType, noteId, expectedKey }) => {
    expect(getAutosaveKey(noteableType, noteId)).toBe(expectedKey);
  });
});
