import { commitActionTypes } from '~/ide/constants';
import eventHub from '~/ide/eventhub';

const removeUnusedFileEditors = (store) => {
  Object.keys(store.state.editor.fileEditors)
    .filter((path) => !store.state.entries[path])
    .forEach((path) => store.dispatch('editor/removeFileEditor', path));
};

export const setupFileEditorsSync = (store) => {
  eventHub.$on('ide.files.change', ({ type, ...payload } = {}) => {
    // Do nothing on file update because the file tree itself hasn't changed.
    if (type === commitActionTypes.update) {
      return;
    }

    if (type === commitActionTypes.move) {
      store.dispatch('editor/renameFileEditor', payload);
    } else {
      // The file tree has changed, but the specific change is not known.
      removeUnusedFileEditors(store);
    }
  });
};
