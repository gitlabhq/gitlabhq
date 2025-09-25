import { escape } from 'lodash';
import { sanitize } from '~/lib/dompurify';

const TEXT_NODE = 3;

const isTextNode = ({ nodeType }) => nodeType === TEXT_NODE;

const isBlank = (str) => !str || /^\s*$/.test(str);

const isMatch = (s1, s2) => !isBlank(s1) && s1.trim() === s2.trim();

const createSpan = (content, classList) => {
  const span = document.createElement('span');
  span.innerText = content;
  span.classList = classList || '';
  return span;
};

const wrapSpacesWithSpans = (text) =>
  text.replace(/ /g, createSpan(' ').outerHTML).replace(/\t/g, createSpan('	').outerHTML);

// eslint-disable-next-line max-params
const wrapTextWithSpan = (el, text, classList, dataset) => {
  if (isTextNode(el) && isMatch(el.textContent, text)) {
    const newEl = createSpan(text.trim(), classList);
    Object.assign(newEl.dataset, dataset);
    el.replaceWith(newEl);
  }
};

const wrapNodes = (text, classList, dataset) => {
  const wrapper = createSpan();
  // Escape HTML entities in the text before processing to prevent HTML injection
  const escapedText = escape(text);
  const unSafeHtml = wrapSpacesWithSpans(escapedText);
  wrapper.innerHTML = sanitize(unSafeHtml);
  wrapper.childNodes.forEach((el) => wrapTextWithSpan(el, text, classList, dataset));
  return wrapper.childNodes;
};

export { wrapNodes, isTextNode };
