export const defaultEditorOptions = {
  model: null,
  readOnly: false,
  contextmenu: true,
  scrollBeyondLastLine: false,
  minimap: {
    enabled: false,
  },
  wordWrap: 'on',
};

export const defaultDiffOptions = {
  ignoreWhitespace: false,
};

export const defaultDiffEditorOptions = {
  quickSuggestions: false,
  occurrencesHighlight: false,
  ignoreTrimWhitespace: false,
};

export const defaultModelOptions = {
  endOfLine: 0,
  insertFinalNewline: true,
  trimTrailingWhitespace: false,
};

export const editorOptions = [
  {
    readOnly: model => Boolean(model.file.file_lock),
    quickSuggestions: model => !(model.language === 'markdown'),
  },
];
