import { isFunction } from 'lodash';

const defaultAttrs = {
  td: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
  th: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
};

const defaultIgnoreAttrs = ['sourceMarkdown', 'sourceMapKey', 'sourceTagName'];

const ignoreAttrs = {
  dd: ['isTerm'],
  dt: ['isTerm'],
};

// Buffers the output of the given action (fn) and returns the output that was written
// to the prosemirror-markdown serializer state output.
export function buffer(state, action = () => {}) {
  const buf = state.out;
  action();
  const retval = state.out.substring(buf.length);
  state.out = buf;
  return retval;
}

export function containsOnlyText(node) {
  if (node.childCount === 1) {
    const child = node.child(0);
    return child.isText && child.marks.length === 0;
  }

  return false;
}

export function containsParagraphWithOnlyText(cell) {
  if (cell.childCount === 1) {
    const child = cell.child(0);
    if (child.type.name === 'paragraph') {
      return containsOnlyText(child);
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

export function ensureSpace(state) {
  state.flushClose();
  if (!state.atBlank() && !state.out.endsWith(' ')) state.write(' ');
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
    const renderInline = forceRenderInline || containsParagraphWithOnlyText(node);
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

    if (same && !overwriteSourcePreservationStrategy) {
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
