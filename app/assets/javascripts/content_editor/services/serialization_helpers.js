import { isFunction } from 'lodash';

const defaultAttrs = {
  td: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
  th: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
};

const defaultIgnoreAttrs = ['sourceMarkdown', 'sourceMapKey', 'sourceTagName'];

const ignoreAttrs = {
  dd: ['isTerm'],
  dt: ['isTerm'],
  blockquote: ['multiline'],
  h1: ['level'],
  h2: ['level'],
  h3: ['level'],
  h4: ['level'],
  h5: ['level'],
  h6: ['level'],
};

// Buffers the output of the given action (fn) and returns the output that was written
// to the prosemirror-markdown serializer state output.
export function buffer(state, action = () => {}, trackOnly = true) {
  const buf = state.out;
  action();
  const retval = state.out.substring(buf.length);
  if (trackOnly) state.out = buf;
  return retval;
}

export function placeholder(state) {
  const id = Math.floor(Math.random() * Date.now() * 10e3).toString(16);
  return {
    replaceWith: (content) => {
      state.out = state.out.replace(new RegExp(id, 'g'), content);
    },
    value: id,
  };
}

export function containsOnlyText(node) {
  if (node.childCount === 1) {
    const child = node.child(0);
    return child.isText && child.marks.length === 0;
  }

  return false;
}

export function containsEmptyParagraph(node) {
  if (node.childCount === 1) {
    const child = node.child(0);
    return child.type.name === 'paragraph' && child.childCount === 0;
  }

  return false;
}

export function containsParagraphWithOnlyText(node) {
  if (node.childCount === 1) {
    const child = node.child(0);
    if (child.type.name === 'paragraph') {
      return child.childCount === 0 || containsOnlyText(child);
    }
  }

  return false;
}

function htmlEncode(str = '') {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/'/g, '&apos;')
    .replace(/"/g, '&quot;');
}

const shouldIgnoreAttr = (tagName, attrKey, attrValue) =>
  ignoreAttrs[tagName]?.includes(attrKey) ||
  defaultIgnoreAttrs.includes(attrKey) ||
  defaultAttrs[tagName]?.[attrKey] === attrValue;

export function openTag(tagName, attrs) {
  let str = `<${tagName}`;

  str += Object.entries(attrs || {})
    .map(([key, value]) => {
      if (shouldIgnoreAttr(tagName, key, value)) return '';

      return ` ${key}="${htmlEncode(value?.toString())}"`;
    })
    .join('');

  return `${str}>`;
}

export function closeTag(tagName) {
  return `</${tagName}>`;
}

const reSpace = /\s$/;
const reBrackets = /[[\](){}]$/;
const rePunctuation = /[.,;:'"`]$/;
const reMarks = /(^|\s)(\*|\*\*|_|__|`|~~)$/;

const regexes = [reSpace, reBrackets, rePunctuation, reMarks];

export function ensureSpace(state) {
  state.flushClose();
  if (!state.atBlank() && !regexes.some((regex) => regex.test(state.out))) state.write(' ');
}

export function renderTagOpen(state, tagName, attrs) {
  state.ensureNewLine();
  state.write(openTag(tagName, attrs));
}

export function renderTagClose(state, tagName, insertNewline = true) {
  state.write(closeTag(tagName));
  if (insertNewline) state.ensureNewLine();
}

export function renderContent(state, node, forceRenderInline) {
  if (node.type.inlineContent) {
    if (containsOnlyText(node)) {
      state.renderInline(node);
    } else {
      state.closeBlock(node);
      state.flushClose();
      state.renderInline(node);
      state.closeBlock(node);
      state.flushClose();
    }
  } else {
    const renderInline =
      forceRenderInline || containsParagraphWithOnlyText(node) || containsOnlyText(node);
    if (!renderInline) {
      state.closeBlock(node);
      state.flushClose();
      state.renderContent(node);
      state.ensureNewLine();
    } else {
      state.renderInline(forceRenderInline ? node : node.child(0));
    }
  }
}

export function renderTextInline(text, state, node) {
  ensureSpace(state);

  const { schema } = node.type;
  const marks = node.marks.filter((mark) => mark.type.spec.code);
  if (marks.length) {
    // ensure text in a code block is properly wrapped in backticks
    state.renderInline(schema.node('paragraph', {}, [schema.text(text, marks)]));
  } else {
    state.write(text);
  }
}

let inBlockquote = false;

export const isInBlockquote = () => inBlockquote;
export const setIsInBlockquote = (value) => {
  inBlockquote = value;
};

const expandPreserveUnchangedConfig = (configOrRender) =>
  isFunction(configOrRender)
    ? { render: configOrRender, overwriteSourcePreservationStrategy: false, inline: false }
    : configOrRender;

export function preserveUnchanged(configOrRender) {
  // eslint-disable-next-line max-params
  return (state, node, parent, index) => {
    const { render, overwriteSourcePreservationStrategy, inline } =
      expandPreserveUnchangedConfig(configOrRender);

    const { sourceMarkdown } = node.attrs;
    const same = state.options.changeTracker.get(node);

    // sourcemaps for elements in blockquotes are not accurate
    if (same && !overwriteSourcePreservationStrategy && !isInBlockquote()) {
      state.write(sourceMarkdown);

      if (!inline) {
        state.closeBlock(node);
      }
    } else {
      render(state, node, parent, index, same, sourceMarkdown);
    }
  };
}

export function preserveUnchangedMark({ open, close, ...restConfig }) {
  // use a buffer to replace the content of the serialized mark with the sourceMarkdown
  // when the mark is unchanged
  let bufferStartPos = -1;

  function startBuffer(state) {
    bufferStartPos = state.out.length;
  }

  function bufferStarted() {
    return bufferStartPos !== -1;
  }

  function endBuffer(state, replace) {
    state.out = state.out.substring(0, bufferStartPos) + replace;
    bufferStartPos = -1;
  }

  return {
    ...restConfig,
    // eslint-disable-next-line max-params
    open: (state, mark, parent, index) => {
      const same = state.options.changeTracker.get(mark);

      if (same) {
        startBuffer(state);
        return '';
      }

      return open(state, mark, parent, index);
    },
    // eslint-disable-next-line max-params
    close: (state, mark, parent, index) => {
      const { sourceMarkdown } = mark.attrs;

      if (bufferStarted()) {
        endBuffer(state, sourceMarkdown);
        return '';
      }

      return close(state, mark, parent, index);
    },
  };
}

export const findChildWithMark = (mark, parent) => {
  let child;
  let offset;
  let index;

  parent.forEach((_child, _offset, _index) => {
    if (mark.isInSet(_child.marks)) {
      child = _child;
      offset = _offset;
      index = _index;
    }
  });

  return child ? { child, offset, index } : null;
};

export function getMarkText(mark, parent) {
  return findChildWithMark(mark, parent).child?.text || '';
}
