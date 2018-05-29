import { n__, s__, sprintf } from '~/locale';
import { DESCRIPTION_TYPE } from '../constants';

export const changeDescriptionNote = (note, descriptionChangedTimes, timeDifferenceMinutes) => {
  const descriptionNote = Object.assign({}, note);

  descriptionNote.note_html = sprintf(
    s__(`MergeRequest|
  <p dir="auto">changed the description %{descriptionChangedTimes} times %{timeDifferenceMinutes}</p>`),
    {
      descriptionChangedTimes,
      timeDifferenceMinutes: n__('within %d minute ', 'within %d minutes ', timeDifferenceMinutes),
    },
    false,
  );

  descriptionNote.times_updated = descriptionChangedTimes;

  return descriptionNote;
};

export const getTimeDifferenceMinutes = (noteBeggining, noteEnd) => {
  const descriptionNoteBegin = new Date(noteBeggining.created_at);
  const descriptionNoteEnd = new Date(noteEnd.created_at);
  let timeDifferenceMinutes = (descriptionNoteEnd - descriptionNoteBegin) / 1000 / 60;
  timeDifferenceMinutes = timeDifferenceMinutes < 1 ? 1 : timeDifferenceMinutes;
  return timeDifferenceMinutes;
};

/**
 * Checks if a note is a system note and if the content is description
 *
 * @param {Object} note
 * @returns {Boolean}
 */
export const isDescriptionSystemNote = note => note.system && note.note === DESCRIPTION_TYPE;

/**
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
        lastDescriptionSystemNote = currentNote;
        lastDescriptionSystemNoteIndex = acc.length;
      } else if (lastDescriptionSystemNote) {
        const timeDifferenceMinutes = getTimeDifferenceMinutes(
          lastDescriptionSystemNote.notes[0],
          note,
        );

        // are they less than 10 minutes appart?
        if (timeDifferenceMinutes > 10) {
          // reset counter
          descriptionChangedTimes = 1;
          // update the previous system note
          lastDescriptionSystemNote = currentNote;
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

          // update the previous system note
          lastDescriptionSystemNote = currentNote;
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
