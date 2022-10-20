import hljs from 'highlight.js/lib/core';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { registerPlugins } from '../plugins/index';

const initHighlightJs = async (fileType, content, language) => {
  const languageDefinition = await languageLoader[language]();

  registerPlugins(hljs, fileType, content);
  hljs.registerLanguage(language, languageDefinition.default);
};

export const highlight = (fileType, content, language) => {
  initHighlightJs(fileType, content, language);
  return hljs.highlight(content, { language }).value;
};
