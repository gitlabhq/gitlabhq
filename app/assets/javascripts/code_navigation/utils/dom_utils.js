const TEXT_NODE = 3;

const isTextNode = ({ nodeType }) => nodeType === TEXT_NODE;

const isBlank = (str) => !str || /^\s*$/.test(str);

const isMatch = (s1, s2) => !isBlank(s1) && s1.trim() === s2.trim();

const createSpan = (content) => {
  const span = document.createElement('span');
  span.innerText = content;
  return span;
};

const wrapSpacesWithSpans = (text) => text.replace(/ /g, createSpan(' ').outerHTML);

const wrapTextWithSpan = (el, text) => {
  if (isTextNode(el) && isMatch(el.textContent, text)) {
    const newEl = createSpan(text.trim());
    el.replaceWith(newEl);
  }
};

const wrapNodes = (text) => {
  const wrapper = createSpan();
  wrapper.innerHTML = wrapSpacesWithSpans(text);
  wrapper.childNodes.forEach((el) => wrapTextWithSpan(el, text));
  return wrapper.childNodes;
};

export { wrapNodes, isTextNode };
