import { getCssVariable } from '~/lib/utils/css_utils';

export const defaultEditorOptions = {
  model: null,
  readOnly: false,
  contextmenu: true,
  scrollBeyondLastLine: false,
  minimap: {
    enabled: false,
  },
  wordWrap: 'on',
  glyphMargin: true,
  automaticLayout: true,
  fontFamily: getCssVariable('--code-editor-font'),
};

export const defaultDiffOptions = {
  ignoreWhitespace: false,
};

export const defaultDiffEditorOptions = {
  ...defaultEditorOptions,
  quickSuggestions: false,
  occurrencesHighlight: false,
  ignoreTrimWhitespace: false,
  readOnly: false,
  renderLineHighlight: 'none',
  hideCursorInOverviewRuler: true,
  glyphMargin: true,
};

export const defaultModelOptions = {
  insertFinalNewline: true,
  trimTrailingWhitespace: false,
};

export const editorOptions = [
  {
    readOnly: (model) => Boolean(model.file.file_lock),
    quickSuggestions: (model) => !(model.language === 'markdown'),
  },
];
