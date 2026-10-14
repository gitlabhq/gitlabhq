import { escape } from 'lodash-es';

const defaultAttrs = {
  td: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
  th: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
};

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

function containsOnlyText(node) {
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

const shouldIgnoreAttr = (tagName, attrKey, attrValue) =>
  ignoreAttrs[tagName]?.includes(attrKey) || defaultAttrs[tagName]?.[attrKey] === attrValue;

export function openTag(tagName, attrs) {
  let str = `<${tagName}`;

  str += Object.entries(attrs || {})
    .map(([key, value]) => {
      if (value === false || shouldIgnoreAttr(tagName, key, value)) return '';
      if (value === true) return ` ${key}`;
      return ` ${key}="${escape(value?.toString())}"`;
    })
    .join('');

  return `${str}>`;
}

export function closeTag(tagName) {
  return `</${tagName}>`;
}

// A letter, digit or literal underscore before a reference reads as a project path
// (`abc#1`, `snake\_#1`), and so does a word ending in a hyphen or dot (`foo-#1`, `v1.#1`);
// punctuation and mark delimiters are boundaries (`#1/#2`, `_#1_`), including punctuation
// written directly after another reference (`#1-#2`).
const reProjectPathCharacter = /([a-zA-Z0-9]|\\_)$/;
const reProjectPathTail = /[a-zA-Z0-9_][a-zA-Z0-9_.-]*[.-]$/;

// Text written directly after a reference that the parser reads as part of it, following the
// reference patterns in `app/models/label.rb`, `milestone.rb` and `user.rb` (`#1abc`, `~bug:x`,
// `%17.5/#2`, `@root/x`), but not sentence punctuation (`@root. Next`, `~bug?`); a quoted name
// ends at its closing quote.
const reContinuesNumericReference = /^[a-zA-Z0-9_]/;
const reContinuesNamedReference = {
  label: /^:{0,2}[a-zA-Z0-9_?.&-]*[a-zA-Z0-9_&-]/,
  milestone: /^[^"\s<]*[a-zA-Z0-9_]/,
  user: /^(?:[a-zA-Z0-9_.-]*[a-zA-Z0-9_-]|\/(?:[a-zA-Z0-9_]|\.[a-zA-Z0-9_.-]*[a-zA-Z0-9_-]))/,
};
const REFERENCE_NODE_TYPES = ['reference', 'referenceLabel'];

function endsWithProjectPath(state, { parent, index }) {
  const match = reProjectPathTail.exec(state.out);
  if (!match) return false;

  // A tail that starts inside the previous reference (`#1-#2`) is read from the document, not
  // from an offset into `state.out`, which serializers such as multiline blockquote rewrite.
  const previous = parent?.maybeChild(index - 1);
  const followsReference =
    previous?.isText &&
    match[0].length > previous.text.length &&
    REFERENCE_NODE_TYPES.includes(parent.maybeChild(index - 2)?.type.name);
  return !followsReference;
}

function ensureSpace(state, position) {
  state.flushClose();
  if (state.atBlank()) return;
  if (reProjectPathCharacter.test(state.out) || endsWithProjectPath(state, position)) {
    state.write(' ');
  }
}

// The unmarked inline text after a node, reading references as written: the parser sees
// `%17.5/#2` as one run of text.
function textAfter(parent, index) {
  let text = '';
  for (let i = index + 1; i < parent.childCount; i += 1) {
    const child = parent.child(i);
    if (child.marks.length) break;
    if (child.isText) text += child.text;
    else if (REFERENCE_NODE_TYPES.includes(child.type.name)) {
      text += child.attrs.originalText || child.attrs.text;
    } else break;
  }
  return text;
}

function ensureSpaceAfterReference(state, text, { node, parent, index }) {
  const next = parent?.maybeChild(index + 1);
  if (!next?.isText || next.marks.length || text.endsWith('"')) return;

  const continues =
    reContinuesNamedReference[node.attrs.referenceType] || reContinuesNumericReference;
  if (continues.test(textAfter(parent, index))) state.write(' ');
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

export function renderTextInline(text, state, { node, parent, index }) {
  ensureSpace(state, { parent, index });

  const { schema } = node.type;
  const marks = node.marks.filter((mark) => mark.type.spec.code);
  if (marks.length) {
    // ensure text in a code block is properly wrapped in backticks
    state.renderInline(schema.node('paragraph', {}, [schema.text(text, marks)]));
  } else {
    state.write(text.replace(/[<>]/g, '\\$&'));
  }

  ensureSpaceAfterReference(state, text, { node, parent, index });
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

// Given a table cell (TableCell or TableHeader), if it's a valid table task item ---
// that is, it contains *only* a single task item, with no other content --- returns the
// TaskItem cell within.
//
// Returns null otherwise.
export function tableCellAsTaskTableItem(cell) {
  if (cell.childCount !== 1) return null;

  const child = cell.child(0);
  if (child.type.name === 'taskList') {
    const taskItem = child.child(0);
    // The editor always has a paragraph beside a task item (so there's somewhere for the
    // cursor to sit if you want to enter content), so we permit it if the task item contains
    // just an empty paragraph. We also permit no child at all for completeness.
    if (taskItem.childCount === 0 || containsEmptyParagraph(taskItem)) {
      return child.child(0);
    }
  }

  return null;
}
