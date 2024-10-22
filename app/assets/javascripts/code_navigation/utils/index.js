import { wrapNodes, isTextNode } from './dom_utils';

export const cachedData = new Map();

const wrappedLines = new WeakSet();

export const getCurrentHoverElement = () => cachedData.get('current');
export const setCurrentHoverElement = (el) => cachedData.set('current', el);

const deprecatedNodeUpdate = ({ d, line, wrapTextNodes }) => {
  let charCount = 0;

  if (wrapTextNodes) {
    line.childNodes.forEach((elm) => {
      // Highlight.js does not wrap all text nodes by default
      // We need all text nodes to be wrapped in order to append code nav attributes
      elm.replaceWith(...wrapNodes(elm.textContent, elm.classList, elm.dataset));
    });
    wrappedLines.add(line);
  }

  const el = [...line.childNodes].find(({ textContent }) => {
    if (charCount === d.start_char) return true;
    charCount += textContent.length;
    return false;
  });

  if (el && !isTextNode(el)) {
    el.dataset.charIndex = d.start_char;
    el.dataset.lineIndex = d.start_line;
    el.classList.add('cursor-pointer', 'code-navigation', 'js-code-navigation');
    el.closest('.line').classList.add('code-navigation-line');
  }
};

export const addInteractionClass = ({ path, d, wrapTextNodes }) => {
  const lineNumber = d.start_line + 1;
  const lines = document
    .querySelector(`[data-path="${path}"]`)
    .querySelectorAll(`.blob-content #LC${lineNumber}, .line_content:not(.old) #LC${lineNumber}`);
  if (!lines?.length) return;

  lines.forEach((line) => {
    if (d.end_line === undefined) {
      // For old cached data we should use the old way of parsing
      deprecatedNodeUpdate({ d, line, wrapTextNodes });
    } else {
      // For new data we can parse slightly differently
      const walker = document.createTreeWalker(line, NodeFilter.SHOW_TEXT);
      let startCharIndex = 0;
      let currentNode = walker.nextNode();
      while (currentNode) {
        if (
          d.start_char >= startCharIndex &&
          d.end_char <= startCharIndex + currentNode.textContent.length
        ) {
          break;
        }
        startCharIndex += currentNode.textContent.length;
        currentNode = walker.nextNode();
      }

      if (currentNode && d.start_char !== d.end_char) {
        const text = currentNode.textContent;
        const textLength = d.end_char - d.start_char;
        const startIndex = d.start_char - startCharIndex;
        const span = document.createElement('span');

        span.textContent = text.slice(startIndex, startIndex + textLength);
        span.dataset.charIndex = d.start_char;
        span.dataset.lineIndex = d.start_line;
        span.classList.add('gl-cursor-pointer', 'code-navigation', 'js-code-navigation');

        currentNode.replaceWith(
          text.slice(0, startIndex),
          span,
          text.slice(startIndex + textLength),
        );

        line.classList.add('code-navigation-line');
      }
    }
  });
};
