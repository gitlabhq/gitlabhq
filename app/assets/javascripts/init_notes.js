import Notes from './notes';

export default () => {
  const dataEl = document.querySelector('.js-notes-data');
  const {
    notesUrl,
    notesIds,
    now,
    diffView,
    autocomplete,
  } = JSON.parse(dataEl.innerHTML);

  // Create a singleton so that we don't need to assign
  // into the window object, we can just access the current isntance with Notes.instance
  Notes.initialize(notesUrl, notesIds, now, diffView, autocomplete);
};
