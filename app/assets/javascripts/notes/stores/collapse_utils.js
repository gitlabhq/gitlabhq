import { n__, s__, sprintf } from '~/locale';

const DESCRIPTION_TYPE = 'changed the description';

const changeDescriptionNote = (note, descriptionChangedTimes, timeDifferenceMinutes) => {
  const descriptionNote = note;
  descriptionNote.note = sprintf(s__(`MergeRequest|
  changed the description %{descriptionChangedTimes} times %{timeDifferenceMinutes}`), {
    descriptionChangedTimes,
    timeDifferenceMinutes: n__('within %d minute, ', 'within %d minutes, ', timeDifferenceMinutes),
  });

  descriptionNote.note_html = sprintf(s__(`MergeRequest|
  <p dir="auto">changed the description %{descriptionChangedTimes} times %{timeDifferenceMinutes}</p>`), {
    descriptionChangedTimes,
    timeDifferenceMinutes: n__('within %d minute, ', 'within %d minutes, ', timeDifferenceMinutes),
  }, false);

  descriptionNote.times_updated = descriptionChangedTimes;

  return descriptionNote;
};

const getTimeDifferenceMinutes = (noteBeggining, noteEnd) => {
  const descriptionNoteBegin = new Date(noteBeggining.created_at);
  const descriptionNoteEnd = new Date(noteEnd.created_at);
  let timeDifferenceMinutes = (descriptionNoteEnd - descriptionNoteBegin) / 1000 / 60;
  timeDifferenceMinutes = timeDifferenceMinutes < 1 ? 1 : timeDifferenceMinutes;
  timeDifferenceMinutes = parseInt(timeDifferenceMinutes, 10);

  return timeDifferenceMinutes;
};

const collapseSystemNotes = (notes) => {
  let descriptionChangedTimes = 1;
  let descriptionNote = null;
  let descriptionNoteIndex = -1;
  let noteCounter = 0;
  let lastValidTimeNote = {};
  let timeDifferenceMinutes = 0;
  const collapsedNotes = [];

  notes.forEach((note) => {
    const currentNote = note.notes[0];
    const isDescriptionNote = currentNote.system &&
      currentNote.note.includes(DESCRIPTION_TYPE);

    if (isDescriptionNote && !descriptionNote) {
      descriptionNote = currentNote;
      descriptionNoteIndex = noteCounter;
      collapsedNotes.push(note);
      noteCounter += 1;
    } else if (descriptionNote) {
      timeDifferenceMinutes =
        getTimeDifferenceMinutes(descriptionNote, currentNote);

      if (timeDifferenceMinutes < 10) {
        descriptionChangedTimes += 1;
        lastValidTimeNote = currentNote;
      } else if (timeDifferenceMinutes === 10) {
        if (descriptionChangedTimes > 1) {
          descriptionNote =
            changeDescriptionNote(descriptionNote, descriptionChangedTimes, timeDifferenceMinutes);

          collapsedNotes[descriptionNoteIndex].notes[0] = descriptionNote;
        }
        if (isDescriptionNote) {
          descriptionNote = currentNote;
          descriptionNoteIndex = noteCounter;
          collapsedNotes.push(note);
          noteCounter += 1;
        } else {
          descriptionNote = null;
        }
        descriptionChangedTimes = 1;
      } else {
        timeDifferenceMinutes =
          getTimeDifferenceMinutes(descriptionNote, lastValidTimeNote);

        if (descriptionChangedTimes > 1) {
          descriptionNote =
            changeDescriptionNote(descriptionNote, descriptionChangedTimes, timeDifferenceMinutes);
          collapsedNotes[descriptionNoteIndex].notes[0] = descriptionNote;
        }

        descriptionNote = currentNote;
        descriptionNoteIndex = noteCounter;
        descriptionChangedTimes = 1;
        collapsedNotes.push(note);
        noteCounter += 1;
      }
    } else {
      collapsedNotes.push(note);
      noteCounter += 1;
    }
  });

  if (descriptionNote && descriptionNoteIndex !== -1 && descriptionChangedTimes > 1) {
    descriptionNote =
      changeDescriptionNote(descriptionNote, descriptionChangedTimes, timeDifferenceMinutes);
    collapsedNotes[descriptionNoteIndex].notes[0] = descriptionNote;
  }

  return collapsedNotes;
};

export default collapseSystemNotes;
