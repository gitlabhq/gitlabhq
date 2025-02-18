import {
  LEGACY_FALLBACKS,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
} from '~/vue_shared/components/source_viewer/constants';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import { highlight } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import {
  HIGHLIGHT_MARK,
  HIGHLIGHT_MARK_REGEX,
  HIGHLIGHT_HTML_START,
  HIGHLIGHT_HTML_END,
} from './constants';

export const isUnsupportedLanguage = (language) => {
  const mappedLanguage = ROUGE_TO_HLJS_LANGUAGE_MAP[language];
  const supportedLanguages = Object.keys(languageLoader);
  const isUnsupported = !supportedLanguages.includes(mappedLanguage);
  return LEGACY_FALLBACKS.includes(language) || isUnsupported;
};

export const markSearchTerm = (str = '', highlights = []) => {
  const chars = str.split('');
  [...highlights].reverse().forEach((highligh) => {
    const [start, end] = highligh;
    chars.splice(end + 1, 0, HIGHLIGHT_MARK);
    chars.splice(start, 0, HIGHLIGHT_MARK);
  });

  return chars.join('');
};

export const cleanLineAndMark = ({ text, highlights } = {}) => {
  const parsedText = highlights?.length > 0 ? markSearchTerm(text, highlights) : text;
  return parsedText.replace(/\r?\n/, '');
};

export const highlightSearchTerm = (highlightedString) => {
  if (highlightedString.length === 0) {
    return '';
  }

  const pattern = new RegExp(`${HIGHLIGHT_MARK_REGEX}(.+?)${HIGHLIGHT_MARK_REGEX}`, 'g');

  const result = highlightedString.replace(
    pattern,
    `${HIGHLIGHT_HTML_START}$1${HIGHLIGHT_HTML_END}`,
  );

  return result;
};

export const initLineHighlight = async (linesData) => {
  const { line, fileUrl } = linesData;
  let { language } = linesData;

  if (fileUrl.endsWith('.gleam')) {
    language = 'gleam';
  }

  if (isUnsupportedLanguage(language)) {
    return line.text;
  }

  const resultData = await highlight(null, cleanLineAndMark(line), language);

  const withHighlightedSearchTerm = highlightSearchTerm(resultData[0].highlightedContent);
  return withHighlightedSearchTerm;
};
