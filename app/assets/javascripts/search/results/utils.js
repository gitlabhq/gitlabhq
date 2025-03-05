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
 * Checks if highlights are close enough to be in the same cluster
 * @param {Array} prevHighlight - Previous highlight [start, end]
 * @param {Array} currentHighlight - Current highlight [start, end]
 * @param {number} maxGap - Maximum gap between highlights
 * @returns {boolean} - True if highlights are close
 */
const areHighlightsClose = (prevHighlight, currentHighlight, maxGap) => {
  return currentHighlight[0] - prevHighlight[1] <= maxGap;
};

/**
 * Groups highlights into clusters based on proximity
 * @param {Array} highlights - Array of highlight positions
 * @param {number} maxGap - Maximum gap between highlights
 * @returns {Array} - Array of highlight clusters
 */
const findHighlightClusters = (highlights, maxGap = MAX_GAP) => {
  if (!highlights?.length) {
    return [];
  }

  const sortedHighlights = sortHighlights(highlights);
  const clusters = [];
  let currentCluster = [sortedHighlights[0]];

  for (let i = 1; i < sortedHighlights.length; i += 1) {
    const prevHighlight = currentCluster[currentCluster.length - 1];
    const currentHighlight = sortedHighlights[i];

    if (areHighlightsClose(prevHighlight, currentHighlight, maxGap)) {
      currentCluster.push(currentHighlight);
    } else {
      clusters.push(currentCluster);
      currentCluster = [currentHighlight];
    }
  }

  clusters.push(currentCluster);
  return clusters;
};

/**
 * Calculates the total highlighted text length in a cluster
 * @param {Array} highlights - Array of highlight positions
 * @returns {number} - Total highlighted length
 */
const getTotalHighlightLength = (highlights) => {
  return highlights.reduce((sum, [start, end]) => sum + (end - start), 0);
};

/**
 * Compares two clusters to find the better one
 * @param {Array} best - Current best cluster
 * @param {Array} current - Cluster to compare
 * @returns {Array} - Better cluster
 */
const compareClusters = (best, current) => {
  if (current.length > best.length) {
    return current;
  }
  if (current.length === best.length) {
    const currentTotal = getTotalHighlightLength(current);
    const bestTotal = getTotalHighlightLength(best);
    return currentTotal > bestTotal ? current : best;
  }
  return best;
};

/**
 * Finds the best cluster of highlights
 * @param {Array} clusters - Array of highlight clusters
 * @returns {Array} - Best cluster
 */
const findBestCluster = (clusters) => {
  return clusters.reduce(compareClusters, clusters[0]);
};

/**
 * Calculates the center position of a highlight cluster
 * @param {Array} cluster - Cluster of highlights
 * @returns {number} - Center position
 */
const calculateClusterCenter = (cluster) => {
  return cluster.reduce((sum, [start, end]) => sum + (start + end) / 2, 0) / cluster.length;
};

/**
 * Adjusts truncation boundaries to not break highlights
 * @param {number} startPos - Initial start position
 * @param {number} endPos - Initial end position
 * @param {Array} highlights - Array of highlight positions
 * @returns {Object} - Adjusted boundaries
 */
const adjustBoundariesForHighlights = (startPos, endPos, highlights) => {
  let adjustedStart = startPos;
  let adjustedEnd = endPos;

  highlights.forEach(([start, end]) => {
    if (adjustedStart > start && adjustedStart < end) {
      adjustedStart = start;
    }
    if (adjustedEnd > start && adjustedEnd < end) {
      adjustedEnd = end;
    }
  });

  return { adjustedStart, adjustedEnd };
};

/**
 * Determines the optimal starting position for truncation based on highlights
 * @param {string} text - The full text
 * @param {Array} highlights - Array of highlight positions
 * @returns {Object} - Initial start and end positions
 */
const initialPosForHighlights = (text, highlights) => {
  const clusters = findHighlightClusters(highlights);
  const bestCluster = findBestCluster(clusters);
  const clusterCenter = calculateClusterCenter(bestCluster);

  const halfLength = Math.floor(MAXIMUM_LINE_LENGTH / 2);
  let initialStartPos;
  let initialEndPos;

  if (clusterCenter > text.length - halfLength) {
    initialEndPos = text.length;
    initialStartPos = Math.max(0, text.length - MAXIMUM_LINE_LENGTH);
  } else if (clusterCenter < halfLength) {
    initialStartPos = 0;
    initialEndPos = Math.min(text.length, MAXIMUM_LINE_LENGTH);
  } else {
    initialStartPos = Math.max(0, Math.floor(clusterCenter - halfLength));
    initialEndPos = Math.min(text.length, Math.floor(clusterCenter + halfLength));
  }

  return { initialStartPos, initialEndPos };
};

/**
 * Determines the optimal text region to keep based on highlights
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

  const hasHighlightsNearEnd = highlights?.some(([, end]) => {
    return end >= text.length - MAXIMUM_LINE_LENGTH;
  });

  if (!hasHighlightsNearEnd && (!highlights || highlights.length <= 2)) {
    return {
      startPos: 0,
      endPos: MAXIMUM_LINE_LENGTH,
      addLeadingEllipsis: false,
      addTrailingEllipsis: true,
    };
  }

  const { initialStartPos, initialEndPos } = initialPosForHighlights(text, highlights);
  const { adjustedStart, adjustedEnd } = adjustBoundariesForHighlights(
    initialStartPos,
    initialEndPos,
    highlights,
  );

  return {
    startPos: adjustedStart,
    endPos: adjustedEnd,
    addLeadingEllipsis: adjustedStart > 0,
    addTrailingEllipsis: adjustedEnd < text.length,
  };
};

/**
 *  * Truncates HTML content while preserving HTML structure using DOMParser
 * @param {string} html - HTML content to truncate
 * @param {string} originalText - Original text before highlighting
 * @param {Array} highlights - Array of highlight positions
 * @returns {string} - Truncated HTML content
 */
export const truncateHtml = (html, originalText, highlights) => {
  if (!html || !html.trim() || html.length <= MAXIMUM_LINE_LENGTH) return html;

  const { startPos, endPos, addLeadingEllipsis, addTrailingEllipsis } = determineOptimalTextRegion(
    originalText,
    highlights,
  );

  const parser = new DOMParser();
  const doc = parser.parseFromString(`<div>${html}</div>`, 'text/html');
  const container = doc.body.firstChild;

  const textNodes = [];
  function collectTextNodes(node) {
    if (node.nodeType === Node.TEXT_NODE) {
      textNodes.push(node);
    } else {
      Array.from(node.childNodes).forEach((child) => collectTextNodes(child));
    }
  }
  collectTextNodes(container);

  let textLength = 0;
  let hasStartedTruncating = false;
  let hasFinishedTruncating = false;

  for (let i = 0; i < textNodes.length; i += 1) {
    const node = textNodes[i];
    const text = node.textContent;

    if (!hasStartedTruncating && textLength < startPos) {
      if (textLength + text.length > startPos) {
        const offset = startPos - textLength;
        node.textContent = (addLeadingEllipsis ? ELLIPSIS : '') + text.substring(offset);
        hasStartedTruncating = true;
      } else {
        node.textContent = '';
      }
      textLength += text.length;
      // eslint-disable-next-line no-continue
      continue;
    }

    hasStartedTruncating = true;

    if (textLength + text.length > endPos) {
      const remainingLength = endPos - textLength;
      node.textContent = text.substring(0, remainingLength) + (addTrailingEllipsis ? ELLIPSIS : '');
      hasFinishedTruncating = true;

      for (let j = i + 1; j < textNodes.length; j += 1) {
        textNodes[j].textContent = '';
      }
      break;
    }

    textLength += text.length;
  }

  if (!hasFinishedTruncating && addTrailingEllipsis) {
    if (textNodes.length > 0) {
      const lastNode = textNodes[textNodes.length - 1];
      lastNode.textContent += ELLIPSIS;
    }
  }

  function removeEmptyNodes(node) {
    const childNodes = Array.from(node.childNodes);

    for (const child of childNodes) {
      if (child.nodeType === Node.ELEMENT_NODE) {
        removeEmptyNodes(child);

        if (!child.textContent.trim() && !child.querySelector('img, svg, canvas')) {
          child.parentNode.removeChild(child);
        }
      }
    }
  }
  removeEmptyNodes(container);

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

  if (isUnsupportedLanguage(language)) {
    const highlightedSearchTerm = highlightSearchTerm(cleanedLine);
    return truncateHtml(highlightedSearchTerm, originalText, highlights);
  }

  const resultData = await highlight(null, cleanedLine, language);

  const withHighlightedSearchTerm = highlightSearchTerm(resultData[0].highlightedContent);

  return truncateHtml(withHighlightedSearchTerm, originalText, highlights);
};
