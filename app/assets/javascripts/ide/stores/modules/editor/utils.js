import { FILE_VIEW_MODE_EDITOR } from '../../../constants';

export const createDefaultFileEditor = () => ({
  editorRow: 1,
  editorColumn: 1,
  fileLanguage: '',
  viewMode: FILE_VIEW_MODE_EDITOR,
});

export const getFileEditorOrDefault = (fileEditors, path) =>
  fileEditors[path] || createDefaultFileEditor();
