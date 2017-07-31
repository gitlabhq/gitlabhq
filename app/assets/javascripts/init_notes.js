/* global Notes */

export default () => {
  const dataEl = document.querySelector('.js-notes-data');
  const {
    notesUrl,
    notesIds,
    now,
    diffView,
    autocomplete,
  } = JSON.parse(dataEl.innerHTML);

  window.notes = new Notes(notesUrl, notesIds, now, diffView, autocomplete);
};
