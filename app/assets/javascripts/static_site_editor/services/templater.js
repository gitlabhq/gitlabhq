const ticks = '```';
const marker = 'sse';
const prefix = `${ticks} ${marker}\n`; // Space intentional due to https://github.com/nhn/tui.editor/blob/6bcec75c69028570d93d973aa7533090257eaae0/libs/to-mark/src/renderer.gfm.js#L26
const postfix = `\n${ticks}`;
const flagPrefix = `${marker}-${Date.now()}`;
const template = `.| |\\t|\\n(?!(\\n|${flagPrefix}))`;
const templatedRegex = new RegExp(`(^${prefix}(${template})+?${postfix}$)`, 'gm');

const nonErbMarkupRegex = new RegExp(`^((<(?!%).+>){1}(${template})+(</.+>){1})$`, 'gm');
const embeddedRubyBlockRegex = new RegExp(`(^<%(${template})+%>$)`, 'gm');
const embeddedRubyInlineRegex = new RegExp(`(^.*[<|&lt;]%(${template})+$)`, 'gm');

// Order is intentional (general to specific) where HTML markup is flagged first, then ERB blocks, then inline ERB
// Order in combo with the `flag()` algorithm is used to mitigate potential duplicate pattern matches (ERB nested in HTML for example)
const orderedPatterns = [nonErbMarkupRegex, embeddedRubyBlockRegex, embeddedRubyInlineRegex];

const unwrap = source => {
  let text = source;
  const matches = text.match(templatedRegex);

  if (matches) {
    matches.forEach(match => {
      const initial = match.replace(`${prefix}`, '').replace(`${postfix}`, '');
      text = text.replace(match, initial);
    });
  }

  return text;
};

const flag = (source, patterns) => {
  let text = source;
  let id = 0;
  const hash = {};

  patterns.forEach(pattern => {
    const matches = text.match(pattern);
    if (matches) {
      matches.forEach(match => {
        const key = `${flagPrefix}${id}`;
        text = text.replace(match, key);
        hash[key] = match;
        id += 1;
      });
    }
  });

  return { text, hash };
};

const wrap = source => {
  const { text, hash } = flag(unwrap(source), orderedPatterns);

  let wrappedSource = text;
  Object.entries(hash).forEach(([key, value]) => {
    wrappedSource = wrappedSource.replace(key, `${prefix}${value}${postfix}`);
  });

  return wrappedSource;
};

export default { wrap, unwrap };
