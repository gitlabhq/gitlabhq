import {
  isDescriptionSystemNote,
  getTimeDifferenceInMinutes,
} from '~/work_items/notes/collapse_utils';
import { workItemSystemNoteWithMetadata } from '../mock_data';

describe('Work items collapse utils', () => {
  it('checks if a system note is of a description type', () => {
    expect(isDescriptionSystemNote(workItemSystemNoteWithMetadata)).toEqual(true);
  });

  it('returns false when a system note is not a description type', () => {
    expect(isDescriptionSystemNote({ ...workItemSystemNoteWithMetadata, system: false })).toEqual(
      false,
    );
  });

  it('gets the time difference between two notes', () => {
    const anotherSystemNote = {
      ...workItemSystemNoteWithMetadata,
      createdAt: '2023-05-06T07:19:37Z',
    };

    // kept the dates 24 hours apart so 24 * 60 mins = 1440
    expect(getTimeDifferenceInMinutes(workItemSystemNoteWithMetadata, anotherSystemNote)).toEqual(
      1440,
    );
  });
});
