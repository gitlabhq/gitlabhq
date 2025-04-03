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
  MAXIMUM_LINE_LENGTH,
  ELLIPSIS,
  MAX_GAP,
  HIGHLIGHT_CLASSES,
} from './constants';

/**
 * Checks if a language is unsupported for syntax highlighting
 * @param {string} language - The language to check
 * @returns {boolean} - True if the language is unsupported
 */
export const isUnsupportedLanguage = (language) => {
  const mappedLanguage = ROUGE_TO_HLJS_LANGUAGE_MAP[language];
  const supportedLanguages = Object.keys(languageLoader);
  const isUnsupported = !supportedLanguages.includes(mappedLanguage);
  return LEGACY_FALLBACKS.includes(language) || isUnsupported;
};

/**
 * Marks the search terms in a string
 * @param {string} str - The string to mark
 * @param {Array} highlights - Array of start/end positions for search matches
 * @returns {string} - String with search terms marked
 */
export const markSearchTerm = (str = '', highlights = []) => {
  if (!str || !highlights?.length) return str;

  const chars = str.split('');
  [...highlights].reverse().forEach((currentHighlight) => {
    const [start, end] = currentHighlight;
    chars.splice(end + 1, 0, HIGHLIGHT_MARK);
    chars.splice(start, 0, HIGHLIGHT_MARK);
  });

  return chars.join('');
};

/**
 * Cleans a line of text and marks search terms
 * @param {Object} params - Input parameters
 * @param {string} params.text - Text to clean
 * @param {Array} params.highlights - Highlight positions
 * @returns {string} - Cleaned text with search terms marked
 */
export const cleanLineAndMark = ({ text, highlights } = {}) => {
  const parsedText = highlights?.length > 0 ? markSearchTerm(text, highlights) : text;
  return parsedText?.replace(/(\r\n|\r|\n)+/g, '');
};

/**
 * Converts invisible markers to HTML highlights
 * @param {string} highlightedString - String with invisible markers
 * @returns {string} - String with HTML highlights
 */
export const highlightSearchTerm = (highlightedString) => {
  if (!highlightedString || highlightedString.length === 0) {
    return '';
  }
  const pattern = new RegExp(`${HIGHLIGHT_MARK_REGEX}(.+?)${HIGHLIGHT_MARK_REGEX}`, 'g');
  return highlightedString.replace(pattern, `${HIGHLIGHT_HTML_START}$1${HIGHLIGHT_HTML_END}`);
};

/**
 * Sorts highlights by starting position
 * @param {Array} highlights - Highlight positions
 * @returns {Array} - Sorted highlights
 */
const sortHighlights = (highlights) => {
  return [...highlights].sort((a, b) => a[0] - b[0]);
};

/**
 * Determines start and end positions for truncation based on context before
 * @param {Number} remainingSpace - calculated number of characters remaining
 * @param {string} text - Original text
 * @param {Number} start - start position character index
 * @returns {Object} - start, end posotions and booleans for adding ellipsis
 */
const getTextRegionsByContextBefore = (remainingSpace, text, start) => {
  const contextBefore = Math.min(remainingSpace / 2, start);

  return {
    startPos: Math.max(0, start - contextBefore),
    endPos: Math.min(text.length, start - contextBefore + MAXIMUM_LINE_LENGTH),
    addLeadingEllipsis: start - contextBefore > 0,
    addTrailingEllipsis: start - contextBefore + MAXIMUM_LINE_LENGTH < text.length,
  };
};

/**
 * Determines the optimal text region to keep based on highlights, strictly enforcing max length
 * @param {string} text - Original text
 * @param {Array} highlights - Array of highlight positions
 * @returns {Object} - Boundaries and flags for truncation
 */
const determineOptimalTextRegion = (text, highlights) => {
  if (!text || text.length <= MAXIMUM_LINE_LENGTH) {
    return {
      startPos: 0,
      endPos: text.length,
      addLeadingEllipsis: false,
      addTrailingEllipsis: false,
    };
  }

  if (!highlights || highlights.length === 0) {
    return {
      startPos: 0,
      endPos: MAXIMUM_LINE_LENGTH,
      addLeadingEllipsis: false,
      addTrailingEllipsis: true,
    };
  }

  const sortedHighlights = sortHighlights(highlights);

  const clusters = [];
  let currentCluster = [sortedHighlights[0]];

  for (let i = 1; i < sortedHighlights.length; i += 1) {
    const prevHighlight = currentCluster[currentCluster.length - 1];
    const currentHighlight = sortedHighlights[i];

    if (
      currentHighlight[0] - prevHighlight[1] <= MAX_GAP &&
      currentHighlight[1] - currentCluster[0][0] <= MAXIMUM_LINE_LENGTH
    ) {
      currentCluster.push(currentHighlight);
    } else {
      clusters.push([...currentCluster]);
      currentCluster = [currentHighlight];
    }
  }

  if (currentCluster.length > 0) {
    clusters.push(currentCluster);
  }

  for (const cluster of clusters) {
    const clusterStart = cluster[0][0];
    const clusterEnd = cluster[cluster.length - 1][1];
    const clusterLength = clusterEnd - clusterStart;

    if (clusterLength <= MAXIMUM_LINE_LENGTH) {
      const remainingSpace = MAXIMUM_LINE_LENGTH - clusterLength;
      return getTextRegionsByContextBefore(remainingSpace, text, clusterStart);
    }
  }

  const firstHighlight = sortedHighlights[0];
  const [start, end] = firstHighlight;
  const highlightLength = end - start;

  if (highlightLength >= MAXIMUM_LINE_LENGTH) {
    return {
      startPos: start,
      endPos: start + MAXIMUM_LINE_LENGTH,
      addLeadingEllipsis: start > 0,
      addTrailingEllipsis: true,
    };
  }

  const remainingSpace = MAXIMUM_LINE_LENGTH - highlightLength;

  return getTextRegionsByContextBefore(remainingSpace, text, start);
};

const getTextOffsetToNode = (container, node) => {
  let offset = 0;
  const traverse = (current, target) => {
    if (current === target) return true;

    if (current.nodeType === Node.TEXT_NODE) {
      offset += current.textContent.length;
    } else {
      for (const child of current.childNodes) {
        if (traverse(child, target)) return true;
      }
    }
    return false;
  };

  traverse(container, node);
  return offset;
};

const collectTextNodes = (node, textNodes = []) => {
  if (node.nodeType === Node.TEXT_NODE) {
    textNodes.push(node);
  } else {
    Array.from(node.childNodes).forEach((child) => collectTextNodes(child, textNodes));
  }
  return textNodes;
};

const removeEmptyNodes = (node) => {
  const childNodes = Array.from(node.childNodes);
  for (const child of childNodes) {
    if (child.nodeType === Node.ELEMENT_NODE) {
      removeEmptyNodes(child);

      // We don't want to remove these nodes even if they are empty
      // as they are still important to the meaning or structure
      const containsHighlightClasses = [...child.classList].some((className) =>
        HIGHLIGHT_CLASSES.includes(className),
      );

      if (
        !child.textContent.trim() &&
        !child.querySelector('img, svg, canvas') &&
        !containsHighlightClasses
      ) {
        child.parentNode.removeChild(child);
      }
    }
  }
};

const getSearchHighlights = (container) => {
  const highlightedSpans = container.querySelectorAll('b.hll');
  const searchHighlights = [];

  for (const span of highlightedSpans) {
    const spanStart = getTextOffsetToNode(container, span);
    const spanEnd = spanStart + span.textContent.length;
    searchHighlights.push([spanStart, spanEnd, span]);
  }

  return searchHighlights;
};

/**
 * Truncates HTML content while preserving HTML structure and all highlighting
 * @param {string} html - HTML content to truncate (with syntax and search highlighting)
 * @param {string} originalText - Original text before highlighting
 * @param {Array} highlights - Array of search term highlight positions
 * @returns {string} - Truncated HTML content
 */
export const truncateHtml = (html, originalText, highlights) => {
  if (!html || !html.trim() || originalText.length <= MAXIMUM_LINE_LENGTH) return html;

  const { startPos, endPos, addLeadingEllipsis, addTrailingEllipsis } = determineOptimalTextRegion(
    originalText,
    highlights,
  );

  const parser = new DOMParser();
  const doc = parser.parseFromString(`<div>${html}</div>`, 'text/html');
  const container = doc.body.firstChild;
  const searchHighlights = getSearchHighlights(container);
  const textNodes = collectTextNodes(container);

  let currentPos = 0;
  let outputLength = 0;
  let hasStartedTruncating = false;
  let hasFinishedTruncating = false;
  const trailingChar = addTrailingEllipsis ? ELLIPSIS : '';

  for (let i = 0; i < textNodes.length; i += 1) {
    const node = textNodes[i];
    const text = node.textContent;
    const nodeLength = text.length;

    if (!hasStartedTruncating && currentPos + nodeLength <= startPos) {
      node.textContent = '';
      currentPos += nodeLength;
      // eslint-disable-next-line no-continue
      continue;
    }

    if (!hasStartedTruncating) {
      hasStartedTruncating = true;
      const offset = startPos - currentPos;

      let newContent = '';
      if (addLeadingEllipsis) {
        newContent += ELLIPSIS;
        outputLength += 1;
      }

      newContent += text.substring(offset);

      if (outputLength + newContent.length > MAXIMUM_LINE_LENGTH) {
        const maxToAdd = MAXIMUM_LINE_LENGTH - outputLength;
        node.textContent = newContent.substring(0, maxToAdd) + trailingChar;
        hasFinishedTruncating = true;
      } else {
        node.textContent = newContent;
        outputLength += newContent.length;
      }

      currentPos += nodeLength;
      // eslint-disable-next-line no-continue
      continue;
    }

    if (!hasFinishedTruncating) {
      if (currentPos + nodeLength > endPos) {
        const remainingLength = endPos - currentPos;

        if (outputLength + remainingLength > MAXIMUM_LINE_LENGTH) {
          const maxToAdd = MAXIMUM_LINE_LENGTH - outputLength;
          node.textContent = text.substring(0, maxToAdd) + trailingChar;
        } else {
          node.textContent = text.substring(0, remainingLength) + trailingChar;
        }

        hasFinishedTruncating = true;
      } else if (outputLength + nodeLength > MAXIMUM_LINE_LENGTH) {
        const maxToAdd = MAXIMUM_LINE_LENGTH - outputLength;
        node.textContent = text.substring(0, maxToAdd) + trailingChar;
        hasFinishedTruncating = true;
      } else {
        outputLength += nodeLength;
      }
    } else {
      node.textContent = '';
    }

    currentPos += nodeLength;

    if (hasFinishedTruncating) {
      for (let j = i + 1; j < textNodes.length; j += 1) {
        textNodes[j].textContent = '';
      }
      break;
    }
  }

  if (!hasFinishedTruncating && addTrailingEllipsis && textNodes.length > 0) {
    const lastNode = textNodes[textNodes.length - 1];
    lastNode.textContent += ELLIPSIS;
  }

  for (const [, , span] of searchHighlights) {
    if (!span.textContent.trim()) {
      span.parentNode.removeChild(span);
    }
  }

  removeEmptyNodes(container);

  const plainTextLength = container.textContent.length;
  if (plainTextLength > MAXIMUM_LINE_LENGTH + 2) {
    const rootElement = container.querySelector('*') || container;
    const tagName = rootElement.tagName.toLowerCase();
    const classNames = rootElement.className ? ` class="${rootElement.className}"` : '';

    const simpleText =
      originalText.substring(startPos, startPos + MAXIMUM_LINE_LENGTH) +
      (originalText.length > startPos + MAXIMUM_LINE_LENGTH ? ELLIPSIS : '');
    return `<${tagName}${classNames}>${simpleText}</${tagName}>`;
  }

  return container.innerHTML;
};

/**
 * Highlights code syntax first, then truncates while preserving HTML structure
 * @param {Object} linesData - Data about the line to highlight
 * @returns {Promise<string>} - Highlighted and truncated HTML
 */
export const initLineHighlight = async (linesData) => {
  const { line, fileUrl } = linesData;
  let { language } = linesData;

  if (fileUrl.endsWith('.gleam')) {
    language = 'gleam';
  }

  const originalText = line.text;
  const highlights = line.highlights || [];

  const cleanedLine = cleanLineAndMark(line);

  let highlightedHtml;
  if (isUnsupportedLanguage(language)) {
    highlightedHtml = highlightSearchTerm(cleanedLine);
  } else {
    const resultData = await highlight(null, cleanedLine, language);
    highlightedHtml = highlightSearchTerm(resultData[0].highlightedContent);
  }
  return truncateHtml(highlightedHtml, originalText, highlights);
};
