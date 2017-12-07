export const changedFiles = state => state.openFiles.filter(file => file.changed);

export const activeFile = state => state.openFiles.find(file => file.active) || null;

export const activeFileExtension = (state) => {
  const file = activeFile(state);
  return file ? `.${file.path.split('.').pop()}` : '';
};

export const canEditFile = (state) => {
  const currentActiveFile = activeFile(state);

  return state.canCommit &&
         (currentActiveFile && !currentActiveFile.renderError && !currentActiveFile.binary);
};

export const addedFiles = state => changedFiles(state).filter(f => f.tempFile);

export const modifiedFiles = state => changedFiles(state).filter(f => !f.tempFile);
