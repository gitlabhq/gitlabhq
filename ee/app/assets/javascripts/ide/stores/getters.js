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

export const addedFiles = state => state.changedFiles.filter(f => f.tempFile);

export const modifiedFiles = state => state.changedFiles.filter(f => !f.tempFile);

export const hasChanges = state => !!state.changedFiles.length;
