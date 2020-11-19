import eventHub from '~/ide/eventhub';
import { commitActionTypes } from '~/ide/constants';

const removeUnusedFileEditors = store => {
  Object.keys(store.state.editor.fileEditors)
    .filter(path => !store.state.entries[path])
    .forEach(path => store.dispatch('editor/removeFileEditor', path));
};

export const setupFileEditorsSync = store => {
  eventHub.$on('ide.files.change', ({ type, ...payload } = {}) => {
    if (type === commitActionTypes.move) {
      store.dispatch('editor/renameFileEditor', payload);
    } else {
      // The files have changed, but the specific change is not known.
      removeUnusedFileEditors(store);
    }
  });
};
