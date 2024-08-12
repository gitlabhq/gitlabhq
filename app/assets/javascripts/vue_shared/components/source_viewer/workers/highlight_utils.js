import { highlightPlugins } from '~/highlight_js/plugins';
import { highlightContent } from '~/highlight_js';
import { LINES_PER_CHUNK, NEWLINE, ROUGE_TO_HLJS_LANGUAGE_MAP } from '../constants';

export const splitByLineBreaks = (content = '') => content.split(/\r?\n/);

// eslint-disable-next-line max-params
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
  let highlightedChunks;

  if (language) {
    const plugins = highlightPlugins(fileType, rawContent, true);
    const highlightedContent = await highlightContent(lang, rawContent, plugins);
    highlightedChunks = splitIntoChunks(language, rawContent, highlightedContent);
  }

  return highlightedChunks;
};

export { highlight, splitIntoChunks };
