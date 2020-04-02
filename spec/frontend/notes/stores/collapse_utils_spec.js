import {
  isDescriptionSystemNote,
  getTimeDifferenceMinutes,
  collapseSystemNotes,
} from '~/notes/stores/collapse_utils';
import { notesWithDescriptionChanges, collapsedSystemNotes } from '../mock_data';

describe('Collapse utils', () => {
  const mockSystemNote = {
    note: 'changed the description',
    note_html: '<p dir="auto">changed the description</p>',
    system: true,
    created_at: '2018-05-14T21:28:00.000Z',
  };

  it('checks if a system note is of a description type', () => {
    expect(isDescriptionSystemNote(mockSystemNote)).toEqual(true);
  });

  it('returns false when a system note is not a description type', () => {
    expect(isDescriptionSystemNote(Object.assign({}, mockSystemNote, { note: 'foo' }))).toEqual(
      false,
    );
  });

  it('gets the time difference between two notes', () => {
    const anotherSystemNote = {
      created_at: '2018-05-14T21:33:00.000Z',
    };

    expect(getTimeDifferenceMinutes(mockSystemNote, anotherSystemNote)).toEqual(5);
  });

  it('collapses all description system notes made within 10 minutes or less from each other', () => {
    expect(collapseSystemNotes(notesWithDescriptionChanges)).toEqual(collapsedSystemNotes);
  });
});
