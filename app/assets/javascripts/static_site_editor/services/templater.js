/**
 * The purpose of this file is to modify Markdown source such that templated code (embedded ruby currently) can be temporarily wrapped and unwrapped in codeblocks:
 * 1. `wrap()`: temporarily wrap in codeblocks (useful for a WYSIWYG editing experience)
 * 2. `unwrap()`: undo the temporarily wrapped codeblocks (useful for Markdown editing experience and saving edits)
 *
 * Without this `templater`, the templated code is otherwise interpreted as Markdown content resulting in loss of spacing, indentation, escape characters, etc.
 *
 */

const ticks = '```';
const marker = 'sse';
const wrapPrefix = `${ticks} ${marker}\n`; // Space intentional due to https://github.com/nhn/tui.editor/blob/6bcec75c69028570d93d973aa7533090257eaae0/libs/to-mark/src/renderer.gfm.js#L26
const wrapPostfix = `\n${ticks}`;
const markPrefix = `${marker}-${Date.now()}`;

const reHelpers = {
  template: `.| |\\t|\\n(?!(\\n|${markPrefix}))`,
  openTag: '<(?!figure|iframe)[a-zA-Z]+.*?>',
  closeTag: '</.+>',
};
const reTemplated = new RegExp(`(^${wrapPrefix}(${reHelpers.template})+?${wrapPostfix}$)`, 'gm');
const rePreexistingCodeBlocks = new RegExp(`(^${ticks}.*\\n(.|\\s)+?${ticks}$)`, 'gm');
const reHtmlMarkup = new RegExp(
  `^((${reHelpers.openTag}){1}(${reHelpers.template})*(${reHelpers.closeTag}){1})$`,
  'gm',
);
const reEmbeddedRubyBlock = new RegExp(`(^<%(${reHelpers.template})+%>$)`, 'gm');
const reEmbeddedRubyInline = new RegExp(`(^.*[<|&lt;]%(${reHelpers.template})+$)`, 'gm');

const patternGroups = {
  ignore: [rePreexistingCodeBlocks],
  // Order is intentional (general to specific) where HTML markup is marked first, then ERB blocks, then inline ERB
  // Order in combo with the `mark()` algorithm is used to mitigate potential duplicate pattern matches (ERB nested in HTML for example)
  allow: [reHtmlMarkup, reEmbeddedRubyBlock, reEmbeddedRubyInline],
};

const mark = (source, groups) => {
  let text = source;
  let id = 0;
  const hash = {};

  Object.entries(groups).forEach(([groupKey, group]) => {
    group.forEach((pattern) => {
      const matches = text.match(pattern);
      if (matches) {
        matches.forEach((match) => {
          const key = `${markPrefix}-${groupKey}-${id}`;
          text = text.replace(match, key);
          hash[key] = match;
          id += 1;
        });
      }
    });
  });

  return { text, hash };
};

const unmark = (text, hash) => {
  let source = text;

  Object.entries(hash).forEach(([key, value]) => {
    const newVal = key.includes('ignore') ? value : `${wrapPrefix}${value}${wrapPostfix}`;
    source = source.replace(key, newVal);
  });

  return source;
};

const unwrap = (source) => {
  let text = source;
  const matches = text.match(reTemplated);

  if (matches) {
    matches.forEach((match) => {
      const initial = match.replace(`${wrapPrefix}`, '').replace(`${wrapPostfix}`, '');
      text = text.replace(match, initial);
    });
  }

  return text;
};

const wrap = (source) => {
  const { text, hash } = mark(unwrap(source), patternGroups);
  return unmark(text, hash);
};

export default { wrap, unwrap };
