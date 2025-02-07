import { DESCRIPTION_TYPE, TIME_DIFFERENCE_VALUE } from '~/notes/constants';

/**
 * Checks the time difference between two notes from their 'created_at' dates
 * returns an integer
 */
export const getTimeDifferenceInMinutes = (noteBeginning, noteEnd) => {
  const descriptionNoteBegin = new Date(noteBeginning.createdAt);
  const descriptionNoteEnd = new Date(noteEnd.createdAt);
  const timeDifferenceMinutes = (descriptionNoteEnd - descriptionNoteBegin) / 1000 / 60;

  return Math.ceil(timeDifferenceMinutes);
};

/**
 * Checks if a note is a system note and if the content is description
 *
 * @param {Object} note
 * @returns {Boolean}
 */
export const isDescriptionSystemNote = (note) => {
  return note.system && note.body === DESCRIPTION_TYPE;
};

/**
 * Collapses the system notes of a description type, e.g. Changed the description, n minutes ago
 * the notes will collapse as long as they happen no more than 10 minutes away from each away
 * in between the notes can be anything, another type of system note
 * (such as 'changed the weight') or a comment.
 *
 * @param {Array} notes
 * @returns {Array}
 */
export const collapseSystemNotes = (notes) => {
  let lastDescriptionSystemNote = null;
  let lastDescriptionSystemNoteIndex = -1;

  return notes.reduce((acc, currentNote) => {
    const note = currentNote.notes.nodes[0];
    let lastStartVersionId = '';

    if (isDescriptionSystemNote(note)) {
      // is it the first one?
      if (!lastDescriptionSystemNote) {
        lastDescriptionSystemNote = note;
      } else {
        const timeDifferenceMinutes = getTimeDifferenceInMinutes(lastDescriptionSystemNote, note);

        // are they less than 10 minutes apart from the same user?
        if (
          timeDifferenceMinutes > TIME_DIFFERENCE_VALUE ||
          note.author.id !== lastDescriptionSystemNote.author.id ||
          lastDescriptionSystemNote.systemNoteMetadata?.descriptionVersion?.deleted
        ) {
          // update the previous system note
          lastDescriptionSystemNote = note;
        } else {
          // set the first version to fetch grouped system note versions

          lastStartVersionId = lastDescriptionSystemNote.systemNoteMetadata?.descriptionVersion?.id;

          // delete the previous one
          acc.splice(lastDescriptionSystemNoteIndex, 1);
        }
      }

      // update the previous system note index
      lastDescriptionSystemNoteIndex = acc.length;

      acc.push({
        notes: {
          nodes: [
            {
              ...note,
              systemNoteMetadata: {
                ...note?.systemNoteMetadata,
                descriptionVersion: {
                  ...note?.systemNoteMetadata?.descriptionVersion,
                  startVersionId: lastStartVersionId,
                },
              },
            },
          ],
        },
      });
    } else {
      acc.push(currentNote);
    }

    return acc;
  }, []);
};
