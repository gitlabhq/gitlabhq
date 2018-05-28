import { n__, s__, sprintf } from '~/locale';
import { DESCRIPTION_TYPE } from '../constants';

/**
 * Changes the description from a note, returns 'changed the description n number of times'
 */
export const changeDescriptionNote = (note, descriptionChangedTimes, timeDifferenceMinutes) => {
  const descriptionNote = Object.assign({}, note);

  descriptionNote.note_html = sprintf(
    s__(`MergeRequest|
  <p dir="auto">changed the description %{descriptionChangedTimes} times %{timeDifferenceMinutes}</p>`),
    {
      descriptionChangedTimes,
      timeDifferenceMinutes: n__(
        'within %d minute, ',
        'within %d minutes, ',
        timeDifferenceMinutes,
      ),
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
  let timeDifferenceMinutes = (descriptionNoteEnd - descriptionNoteBegin) / 1000 / 60;
  timeDifferenceMinutes = timeDifferenceMinutes < 1 ? 1 : timeDifferenceMinutes;
  timeDifferenceMinutes = parseInt(timeDifferenceMinutes, 10);

  return timeDifferenceMinutes;
};

/**
 * Check if a note object is of a 'changed description' type as well if it as a system note
 */

export const isSystemNote = note => note.system && note.note === DESCRIPTION_TYPE;

/**
 * Collapses the system notes of a description type, e.g. Changed the description, n minutes ago
 * the notes will collapse as long as they happen no more than 10 minutes away from each away
 * in between the notes can be anything, another type of system note
 * (such as 'changed the weight') or a comment.
 */

export const collapseSystemNotes = notes => {
  let lastValidSystemNoteIndex = -1;
  let previousSystemNote = null;
  let descriptionChangedTimes = 1;
  let timeDifferenceMinutes = 0;
  let lastValidTimeNote = null;

  const collapsedNotes = notes.slice(0).reduce((acc, current) => {
    if (isSystemNote(current.notes[0]) && !previousSystemNote) {
      previousSystemNote = current.notes[0];
      lastValidSystemNoteIndex = acc.length;
      acc.push(current);
    } else if (isSystemNote(current.notes[0]) && previousSystemNote) {
      timeDifferenceMinutes = getTimeDifferenceMinutes(previousSystemNote, current.notes[0]);

      if (timeDifferenceMinutes < 10) {
        descriptionChangedTimes += 1;
        lastValidTimeNote = current.notes[0];
      } else if (timeDifferenceMinutes === 10) {
        if (descriptionChangedTimes > 1) {
          const changedNote = changeDescriptionNote(
            previousSystemNote,
            descriptionChangedTimes,
            timeDifferenceMinutes,
          );
          const noteInfo = acc[lastValidSystemNoteIndex];
          noteInfo.notes[0] = changedNote;
          acc.splice(lastValidSystemNoteIndex, 1, noteInfo);
        }
        if (isSystemNote(current.notes[0])) {
          previousSystemNote = current.notes[0];
          lastValidSystemNoteIndex = acc.length;
          acc.push(current);
        } else {
          previousSystemNote = null;
        }
        descriptionChangedTimes = 1;
      } else {
        timeDifferenceMinutes = getTimeDifferenceMinutes(previousSystemNote, lastValidTimeNote);

        if (descriptionChangedTimes > 1) {
          const changedNote = changeDescriptionNote(
            previousSystemNote,
            descriptionChangedTimes,
            timeDifferenceMinutes,
          );
          const noteInfo = acc[lastValidSystemNoteIndex];
          noteInfo.notes[0] = changedNote;
          acc.splice(lastValidSystemNoteIndex, 1, noteInfo);
        }

        previousSystemNote = current.notes[0];
        lastValidSystemNoteIndex = acc.length;
        descriptionChangedTimes = 1;
        acc.push(current);
      }
    } else {
      acc.push(current);
    }
    return acc;
  }, []);

  if (previousSystemNote && lastValidSystemNoteIndex !== -1 && descriptionChangedTimes > 1) {
    previousSystemNote = changeDescriptionNote(
      previousSystemNote,
      descriptionChangedTimes,
      timeDifferenceMinutes,
    );
    collapsedNotes[lastValidSystemNoteIndex].notes[0] = previousSystemNote;
  }

  return collapsedNotes;
};

// for babel-rewire
export default {};
