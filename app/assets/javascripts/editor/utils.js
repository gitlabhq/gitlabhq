import { editor as monacoEditor, languages as monacoLanguages } from 'monaco-editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';

export const clearDomElement = (el) => {
  if (!el || !el.firstChild) return;

  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
};

export const setupEditorTheme = () => {
  const themeName = window.gon?.user_color_scheme || DEFAULT_THEME;
  const theme = themes.find((t) => t.name === themeName);
  if (theme) monacoEditor.defineTheme(themeName, theme.data);
  monacoEditor.setTheme(theme ? themeName : DEFAULT_THEME);
};

export const getBlobLanguage = (path) => {
  const defaultLanguage = 'plaintext';

  if (!path) {
    return defaultLanguage;
  }

  const blobPath = path.split('/').pop();
  const ext = blobPath.includes('.') ? `.${blobPath.split('.').pop()}` : blobPath;
  const language = monacoLanguages
    .getLanguages()
    .find((lang) => lang.extensions.indexOf(ext.toLowerCase()) !== -1);
  return language ? language.id : defaultLanguage;
};

export const setupCodeSnippet = (el) => {
  monacoEditor.colorizeElement(el);
  setupEditorTheme();
};
