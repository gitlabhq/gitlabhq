import Notes from './deprecated_notes';

export default () => {
  const dataEl = document.querySelector('.js-notes-data');
  const { notesUrl, now, diffView, enableGFM } = JSON.parse(dataEl.innerHTML);

  // Create a singleton so that we don't need to assign
  // into the window object, we can just access the current isntance with Notes.instance
  Notes.initialize(notesUrl, now, diffView, enableGFM);
};
