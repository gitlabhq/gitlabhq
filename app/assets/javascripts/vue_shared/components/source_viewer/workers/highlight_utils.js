import hljs from 'highlight.js/lib/core';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { registerPlugins } from '../plugins/index';
import { LINES_PER_CHUNK, NEWLINE, ROUGE_TO_HLJS_LANGUAGE_MAP } from '../constants';

const loadLanguage = async (language) => {
  const languageDefinition = await languageLoader[language]();
  hljs.registerLanguage(language, languageDefinition.default);
};

const loadSubLanguages = async (languageDefinition) => {
  // Some files can contain sub-languages (i.e., Svelte); this ensures that sub-languages are also loaded
  if (!languageDefinition?.contains) return;

  // generate list of languages to load
  const languages = new Set(
    languageDefinition.contains
      .filter((component) => Boolean(component.subLanguage))
      .map((component) => component.subLanguage),
  );

  if (languageDefinition.subLanguage) {
    languages.add(languageDefinition.subLanguage);
  }

  await Promise.all([...languages].map(loadLanguage));
};

const initHighlightJs = async (fileType, content, language) => {
  registerPlugins(hljs, fileType, content, true);
  await loadLanguage(language);
  await loadSubLanguages(hljs.getLanguage(language));
};

const splitByLineBreaks = (content = '') => content.split(/\r?\n/);

const createChunk = (language, rawChunkLines, highlightedChunkLines = [], startingFrom = 0) => ({
  highlightedContent: highlightedChunkLines.join(NEWLINE),
  rawContent: rawChunkLines.join(NEWLINE),
  totalLines: rawChunkLines.length,
  startingFrom,
  language,
});

const splitIntoChunks = (language, rawContent, highlightedContent) => {
  const result = [];
  const splitRawContent = splitByLineBreaks(rawContent);
  const splitHighlightedContent = splitByLineBreaks(highlightedContent);

  for (let i = 0; i < splitRawContent.length; i += LINES_PER_CHUNK) {
    const chunkIndex = Math.floor(i / LINES_PER_CHUNK);
    const highlightedChunk = splitHighlightedContent.slice(i, i + LINES_PER_CHUNK);
    const rawChunk = splitRawContent.slice(i, i + LINES_PER_CHUNK);
    result[chunkIndex] = createChunk(language, rawChunk, highlightedChunk, i);
  }

  return result;
};

const highlight = async (fileType, rawContent, lang) => {
  const language = ROUGE_TO_HLJS_LANGUAGE_MAP[lang.toLowerCase()];
  let result;

  if (language) {
    await initHighlightJs(fileType, rawContent, language);
    const highlightedContent = hljs.highlight(rawContent, { language }).value;
    result = splitIntoChunks(language, rawContent, highlightedContent);
  }

  return result;
};

export { highlight, splitIntoChunks };
