import { wrapNodes, isTextNode } from './dom_utils';

export const cachedData = new Map();

export const getCurrentHoverElement = () => cachedData.get('current');
export const setCurrentHoverElement = (el) => cachedData.set('current', el);

export const addInteractionClass = ({ path, d, wrapTextNodes }) => {
  const lineNumber = d.start_line + 1;
  const lines = document
    .querySelector(`[data-path="${path}"]`)
    .querySelectorAll(`.blob-content #LC${lineNumber}, .line_content:not(.old) #LC${lineNumber}`);
  if (!lines?.length) return;

  lines.forEach((line) => {
    let charCount = 0;

    if (wrapTextNodes) {
      line.childNodes.forEach((elm) => {
        // Highlight.js does not wrap all text nodes by default
        // We need all text nodes to be wrapped in order to append code nav attributes
        elm.replaceWith(...wrapNodes(elm.textContent, elm.classList));
      });
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
  });
};
