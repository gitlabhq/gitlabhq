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

export default [
  {
    readOnly: model => !!model.file.file_lock,
  },
];
