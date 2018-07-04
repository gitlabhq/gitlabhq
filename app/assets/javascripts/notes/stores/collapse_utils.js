import { n__, s__, sprintf } from '~/locale';
import { DESCRIPTION_TYPE } from '../constants';

/**
 * Changes the description from a note, returns 'changed the description n number of times'
 */
export const changeDescriptionNote = (note, descriptionChangedTimes, timeDifferenceMinutes) => {
  const descriptionNote = Object.assign({}, note);

  descriptionNote.note_html = sprintf(
    s__(`MergeRequest|
  %{paragraphStart}changed the description %{descriptionChangedTimes} times %{timeDifferenceMinutes}%{paragraphEnd}`),
    {
      paragraphStart: '<p dir="auto">',
      paragraphEnd: '</p>',
      descriptionChangedTimes,
      timeDifferenceMinutes: n__('within %d minute ', 'within %d minutes ', timeDifferenceMinutes),
    },
    false,
  );

  descriptionNote.times_updated = descriptionChangedTimes;

  return descriptionNote;
};

/**
 * Checks the time difference between two notes from their 'created_at' dates
 * returns an integer
 */

export const getTimeDifferenceMinutes = (noteBeggining, noteEnd) => {
  const descriptionNoteBegin = new Date(noteBeggining.created_at);
  const descriptionNoteEnd = new Date(noteEnd.created_at);
  const timeDifferenceMinutes = (descriptionNoteEnd - descriptionNoteBegin) / 1000 / 60;

  return Math.ceil(timeDifferenceMinutes);
};

/**
 * Checks if a note is a system note and if the content is description
 *
 * @param {Object} note
 * @returns {Boolean}
 */
export const isDescriptionSystemNote = note => note.system && note.note === DESCRIPTION_TYPE;

/**
 * Collapses the system notes of a description type, e.g. Changed the description, n minutes ago
 * the notes will collapse as long as they happen no more than 10 minutes away from each away
 * in between the notes can be anything, another type of system note
 * (such as 'changed the weight') or a comment.
 *
 * @param {Array} notes
 * @returns {Array}
 */
export const collapseSystemNotes = notes => {
  let lastDescriptionSystemNote = null;
  let lastDescriptionSystemNoteIndex = -1;
  let descriptionChangedTimes = 1;

  return notes.slice(0).reduce((acc, currentNote) => {
    const note = currentNote.notes[0];

    if (isDescriptionSystemNote(note)) {
      // is it the first one?
      if (!lastDescriptionSystemNote) {
        lastDescriptionSystemNote = note;
        lastDescriptionSystemNoteIndex = acc.length;
      } else if (lastDescriptionSystemNote) {
        const timeDifferenceMinutes = getTimeDifferenceMinutes(
          lastDescriptionSystemNote,
          note,
        );

        // are they less than 10 minutes appart?
        if (timeDifferenceMinutes > 10) {
          // reset counter
          descriptionChangedTimes = 1;
          // update the previous system note
          lastDescriptionSystemNote = note;
          lastDescriptionSystemNoteIndex = acc.length;
        } else {
          // increase counter
          descriptionChangedTimes += 1;

          // delete the previous one
          acc.splice(lastDescriptionSystemNoteIndex, 1);

          // replace the text of the current system note with the collapsed note.
          currentNote.notes.splice(
            0,
            1,
            changeDescriptionNote(note, descriptionChangedTimes, timeDifferenceMinutes),
          );

          // update the previous system note index
          lastDescriptionSystemNoteIndex = acc.length;
        }
      }
    }
    acc.push(currentNote);
    return acc;
  }, []);
};

// for babel-rewire
export default {};
