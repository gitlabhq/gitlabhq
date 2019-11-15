import { DESCRIPTION_TYPE } from '../constants';

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

  return notes.slice(0).reduce((acc, currentNote) => {
    const note = currentNote.notes[0];

    if (isDescriptionSystemNote(note)) {
      // is it the first one?
      if (!lastDescriptionSystemNote) {
        lastDescriptionSystemNote = note;
        lastDescriptionSystemNoteIndex = acc.length;
      } else if (lastDescriptionSystemNote) {
        const timeDifferenceMinutes = getTimeDifferenceMinutes(lastDescriptionSystemNote, note);

        // are they less than 10 minutes apart from the same user?
        if (timeDifferenceMinutes > 10 || note.author.id !== lastDescriptionSystemNote.author.id) {
          // update the previous system note
          lastDescriptionSystemNote = note;
          lastDescriptionSystemNoteIndex = acc.length;
        } else {
          // set the first version to fetch grouped system note versions
          note.start_description_version_id = lastDescriptionSystemNote.description_version_id;

          // delete the previous one
          acc.splice(lastDescriptionSystemNoteIndex, 1);

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
