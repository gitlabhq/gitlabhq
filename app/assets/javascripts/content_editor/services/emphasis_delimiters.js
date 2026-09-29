import { MarkdownSerializerState } from '~/lib/prosemirror_markdown_serializer';

// A delimiter run can only open or close emphasis when the characters around it allow it
// (CommonMark "flanking"). prosemirror-markdown writes delimiters without checking, so a
// span like bold `see!` followed by `ify` saves as `**see!**ify`, which renders literally.
//
// The checks below mirror comrak's `scan_delims` (src/parser/inlines.rs in comrak 0.55.0,
// shipped through gitlab-glfm-markdown 0.0.43) with the options set in
// lib/banzai/filter/markdown_engines/glfm_markdown.rb: strikethrough and cjk_friendly_emphasis.

const LINE_EDGE = '\n';
const EDGE = { char: LINE_EDGE, index: -1 };
// With strikethrough on, comrak skips tildes when it looks for the characters beside a run.
const TILDE = '~';
const DELIMITER_CHARACTERS = ['*', '_', TILDE];

// comrak's `is_cjk` (src/parser/inlines/cjk.rs), the CJK ranges of markdown-cjk-friendly as of
// Unicode 16.
const CJK_RANGES = [
  [0x1100, 0x11ff],
  [0x20a9, 0x20a9],
  [0x2329, 0x232a],
  [0x2630, 0x2637],
  [0x268a, 0x268f],
  [0x2e80, 0x2e99],
  [0x2e9b, 0x2ef3],
  [0x2f00, 0x2fd5],
  [0x2ff0, 0x303e],
  [0x3041, 0x3096],
  [0x3099, 0x30ff],
  [0x3105, 0x312f],
  [0x3131, 0x318e],
  [0x3190, 0x31e5],
  [0x31ef, 0x321e],
  [0x3220, 0x3247],
  [0x3250, 0xa48c],
  [0xa490, 0xa4c6],
  [0xa960, 0xa97c],
  [0xac00, 0xd7a3],
  [0xd7b0, 0xd7c6],
  [0xd7cb, 0xd7fb],
  [0xf900, 0xfaff],
  [0xfe10, 0xfe19],
  [0xfe30, 0xfe52],
  [0xfe54, 0xfe66],
  [0xfe68, 0xfe6b],
  [0xff01, 0xffbe],
  [0xffc2, 0xffc7],
  [0xffca, 0xffcf],
  [0xffd2, 0xffd7],
  [0xffda, 0xffdc],
  [0xffe0, 0xffe6],
  [0xffe8, 0xffee],
  [0x16fe0, 0x16fe4],
  [0x16ff0, 0x16ff6],
  [0x17000, 0x18cd5],
  [0x18cff, 0x18d1e],
  [0x18d80, 0x18df2],
  [0x1aff0, 0x1aff3],
  [0x1aff5, 0x1affb],
  [0x1affd, 0x1affe],
  [0x1b000, 0x1b122],
  [0x1b132, 0x1b132],
  [0x1b150, 0x1b152],
  [0x1b155, 0x1b155],
  [0x1b164, 0x1b167],
  [0x1b170, 0x1b2fb],
  [0x1d300, 0x1d356],
  [0x1d360, 0x1d376],
  [0x1f200, 0x1f200],
  [0x1f202, 0x1f202],
  [0x1f210, 0x1f219],
  [0x1f21b, 0x1f22e],
  [0x1f230, 0x1f231],
  [0x1f237, 0x1f237],
  [0x1f23b, 0x1f23b],
  [0x1f240, 0x1f248],
  [0x1f260, 0x1f265],
  [0x20000, 0x3fffd],
];
// The curly quotes that comrak treats as CJK punctuation after U+FE01.
const AMBIGUOUS_QUOTES = ['\u2018', '\u2019', '\u201c', '\u201d'];

const WHITESPACE = /^\p{White_Space}$/u;
const PUNCTUATION = /^[\p{P}\p{S}]$/u;
// What comrak's autolinker ends a link at, accepts in an email address, and accepts before `www.`.
const ASCII_WHITESPACE = /[ \t\n\r\v\f]/;
const EMAIL_LOCAL_PART = /[A-Za-z0-9.+\-_]/;
const EMAIL_DOMAIN = /[A-Za-z0-9.\-_]/;
const WWW_PRECEDING = /[*_~([]/;

const isWhitespace = (char) => WHITESPACE.test(char);
const isPunctuation = (char) => PUNCTUATION.test(char);
const isWordCharacter = (char) => !isWhitespace(char) && !isPunctuation(char);

const isCjk = (char) => {
  const codePoint = char.codePointAt(0);
  let low = 0;
  let high = CJK_RANGES.length - 1;

  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const [start, end] = CJK_RANGES[middle];

    if (codePoint < start) high = middle - 1;
    else if (codePoint > end) low = middle + 1;
    else return true;
  }

  return false;
};

const isIdeographicVariationSelector = (char) =>
  char.codePointAt(0) >= 0xe0100 && char.codePointAt(0) <= 0xe01ef;
// comrak's "non-emoji general purpose variation selector": its flanking checks look past it.
const isTextVariationSelector = (char) =>
  char.codePointAt(0) >= 0xfe00 && char.codePointAt(0) <= 0xfe0e;
const isAmbiguousQuoteSelector = (before, twoBefore) =>
  before === '\ufe01' && AMBIGUOUS_QUOTES.includes(twoBefore);

const isLeftFlanking = (before, after, twoBefore) =>
  !isWhitespace(after) &&
  (!isPunctuation(after) ||
    isWhitespace(before) ||
    isCjk(after) ||
    (isTextVariationSelector(before)
      ? isCjk(twoBefore) || isPunctuation(twoBefore)
      : isCjk(before) || isIdeographicVariationSelector(before) || isPunctuation(before)));

const isRightFlanking = (before, after, twoBefore) =>
  !isWhitespace(before) &&
  (isCjk(after) ||
    isWhitespace(after) ||
    isPunctuation(after) ||
    !(isTextVariationSelector(before)
      ? !isCjk(twoBefore) &&
        isPunctuation(twoBefore) &&
        !isAmbiguousQuoteSelector(before, twoBefore)
      : !isCjk(before) && isPunctuation(before)));

/**
 * Whether a delimiter run of `delimiter` can open emphasis between the characters `before` and
 * `after`. `twoBefore` is the character before `before`, which comrak consults when `before` is a
 * variation selector.
 */
export const canOpen = (delimiter, { before, after, twoBefore = LINE_EDGE }) => {
  const leftFlanking = isLeftFlanking(before, after, twoBefore);
  if (delimiter !== '_') return leftFlanking;

  const beside = isTextVariationSelector(before) ? twoBefore : before;
  return leftFlanking && (!isRightFlanking(before, after, twoBefore) || isPunctuation(beside));
};

/**
 * Whether a delimiter run of `delimiter` can close emphasis between `before` and `after`.
 */
export const canClose = (delimiter, { before, after, twoBefore = LINE_EDGE }) => {
  const rightFlanking = isRightFlanking(before, after, twoBefore);
  if (delimiter !== '_') return rightFlanking;

  return rightFlanking && (!isLeftFlanking(before, after, twoBefore) || isPunctuation(after));
};

const isLowSurrogate = (text, index) =>
  text.charCodeAt(index) >= 0xdc00 && text.charCodeAt(index) <= 0xdfff;

const isEscaped = (text, index) => {
  let backslashes = 0;
  while (text[index - backslashes - 1] === '\\') backslashes += 1;
  return backslashes % 2 === 1;
};

// Finds the range containing `index` in ranges sorted by `start` that do not overlap.
const findSpan = (spans, index) => {
  let low = 0;
  let high = spans.length - 1;

  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const span = spans[middle];

    if (index < span.start) high = middle - 1;
    else if (index >= span.end) low = middle + 1;
    else return span;
  }

  return null;
};

// Adjacent delimiters of the same character form one run, as the parser sees them (`***`).
const toRuns = (delimiters, charOf) =>
  delimiters.reduce((runs, delimiter) => {
    const last = runs[runs.length - 1];
    const char = charOf(delimiter);

    if (last && last.end === delimiter.start && last.char === char) {
      last.end = delimiter.end;
      last.delimiters.push(delimiter);
    } else {
      runs.push({ start: delimiter.start, end: delimiter.end, char, delimiters: [delimiter] });
    }

    return runs;
  }, []);

/**
 * Repairs the delimiter runs of one block that cannot open or close: an italic `_` pair becomes
 * `*`, or the text character beside the run becomes a numeric character reference.
 */
function repairDelimiters({ out, delimiters, textSpans }) {
  // Edits by position in `out`, each replacing one character. Applied once at the end.
  let edits = new Map();

  const charBefore = (index) => {
    if (index <= 0) return EDGE;

    let position = index - 1;
    while (position > 0 && (isLowSurrogate(out, position) || out[position] === TILDE))
      position -= 1;

    const edit = edits.get(position);
    if (edit) return { char: edit[edit.length - 1], index: position };

    const char = String.fromCodePoint(out.codePointAt(position));
    return char === TILDE ? EDGE : { char, index: position };
  };

  const charAfter = (index) => {
    if (index >= out.length) return EDGE;

    let position = index;
    while (position < out.length - 1 && out[position] === TILDE) position += 1;

    const edit = edits.get(position);
    if (edit) return { char: edit[0], index: position };

    const char = String.fromCodePoint(out.codePointAt(position));
    return char === TILDE ? EDGE : { char, index: position };
  };

  const surroundings = (run) => {
    const before = charBefore(run.start);
    const twoBefore = isTextVariationSelector(before.char) ? charBefore(before.index) : EDGE;

    return { before, twoBefore, after: charAfter(run.end) };
  };

  const charAt = (index) => (edits.get(index) || out[index] || '')[0];
  const runsOf = (list) => toRuns(list, (delimiter) => charAt(delimiter.start));

  // A run that the output extends with characters it did not record is left alone.
  const isRecordedRun = (run) =>
    (charAt(run.start - 1) !== run.char || isEscaped(out, run.start - 1)) &&
    charAt(run.end) !== run.char;

  const isValid = (run) => {
    const { before, twoBefore, after } = surroundings(run);
    const sides = { before: before.char, after: after.char, twoBefore: twoBefore.char };

    return run.delimiters.every(({ opens }) => (opens ? canOpen : canClose)(run.char, sides));
  };

  const judge = (runs) => {
    const recorded = runs.filter(isRecordedRun);
    const valid = recorded.filter(isValid);

    return {
      invalid: recorded.length - valid.length,
      valid: new Set(valid.flatMap((run) => run.delimiters)),
      foreign: new Set(runs.filter((run) => !isRecordedRun(run)).flatMap((run) => run.delimiters)),
    };
  };
  const keeps = (before, after) =>
    [...before.valid].every((delimiter) => after.valid.has(delimiter)) &&
    [...after.foreign].every((delimiter) => before.foreign.has(delimiter));

  const initial = judge(runsOf(delimiters));
  if (!initial.invalid) return out;

  // comrak links URLs and email addresses in text (`autolink`, `relaxed_autolinks`). It reads a
  // URL's raw characters, so a reference inside one changes the link; it finds email addresses in
  // decoded text, so only a delimiter inside one that starts to open or close splits the link.
  const firstPosition = Math.min(
    ...[textSpans[0], delimiters[0]].filter(Boolean).map(({ start }) => start),
  );
  let regionStart = firstPosition;
  while (regionStart > 0 && !ASCII_WHITESPACE.test(out[regionStart - 1])) regionStart -= 1;

  // Where comrak's `url_match` and `www_match` end a link: at ASCII whitespace or `<`, and not at
  // all when a markdown link's `](` comes first.
  const urlEnd = (index) => {
    let end = index;
    let lessThan = -1;
    while (end < out.length && !ASCII_WHITESPACE.test(out[end])) {
      if (out[end] === '(' && out[end - 1] === ']') return -1;
      if (out[end] === '<' && lessThan < 0) lessThan = end;
      end += 1;
    }
    return lessThan < 0 ? end : lessThan;
  };
  const urls = [];
  const emails = [];
  [...out.slice(regionStart).matchAll(/:\/\/|www\.|@/g)].forEach(({ 0: match, index: offset }) => {
    const index = regionStart + offset;
    if (!findSpan(textSpans, index)) return;

    let start = index;
    if (match === '@') {
      const rewind = () => {
        while (EMAIL_LOCAL_PART.test(out[start - 1] || '')) start -= 1;
      };
      rewind();
      const protocol = /(mailto|xmpp):$/.exec(out.slice(Math.max(0, start - 7), start));
      if (protocol) {
        start -= protocol[0].length;
        rewind();
      }
      let end = index + 1;
      while (EMAIL_DOMAIN.test(out[end] || '')) end += 1;
      if (start < index && out.slice(index, end).includes('.')) emails.push({ start, end });
      return;
    }

    if (match[0] === 'w') {
      if (
        index > 0 &&
        !ASCII_WHITESPACE.test(out[index - 1]) &&
        !WWW_PRECEDING.test(out[index - 1])
      )
        return;
    } else {
      while (/[A-Za-z]/.test(out[start - 1] || '')) start -= 1;
    }

    const end = urlEnd(index);
    if (end > index) urls.push({ start, end });
  });
  const isInUrl = (index) => urls.some(({ start, end }) => index >= start && index < end);
  const isInsideEmail = ({ start, end }) =>
    emails.some((email) => start > email.start && end < email.end);
  const isInEmail = (index) => emails.some(({ start, end }) => index >= start && index < end);

  const delimiterIndex = new Map(delimiters.map((delimiter, index) => [delimiter, index]));
  const cluster = (delimiter) => {
    let first = delimiterIndex.get(delimiter);
    while (first > 0 && delimiters[first - 1].end === delimiters[first].start) first -= 1;
    let last = delimiterIndex.get(delimiter);
    while (last < delimiters.length - 1 && delimiters[last].end === delimiters[last + 1].start)
      last += 1;

    return delimiters.slice(first, last + 1);
  };
  const clustersOf = (pair) =>
    [...new Set(pair.flatMap(cluster))].sort((a, b) => a.start - b.start);

  const initialInvalid = runsOf(delimiters).filter((run) => isRecordedRun(run) && !isValid(run));
  const touches = (delimiter, run) =>
    delimiter.end === run.start ||
    delimiter.start === run.end ||
    run.delimiters.includes(delimiter);
  const italicPairs = [
    ...new Set(
      delimiters
        .filter(({ text }) => text === '_')
        .filter((delimiter) => initialInvalid.some((run) => touches(delimiter, run)))
        .map(({ pair }) => pair),
    ),
  ]
    .map((pair) => delimiters.filter((delimiter) => delimiter.pair === pair))
    .filter(
      (pair) =>
        pair.length === 2 &&
        !pair.some((delimiter) => isInUrl(delimiter.start) || isInsideEmail(delimiter)),
    );

  // Writing a character as a reference puts punctuation next to its other neighbour. A literal
  // `_` there could start to open or close emphasis, so it is escaped as well; any other
  // delimiter character there means the character is left as it is.
  const neighbourEdits = (index, length, side) => {
    const step = side === 'after' ? 1 : -1;
    let position = side === 'after' ? index + length : index - 1;
    if (side === 'before' && isLowSurrogate(out, position)) position -= 1;

    const char = out[position];
    if (!DELIMITER_CHARACTERS.includes(char) || edits.has(position)) return [];
    if (isEscaped(out, position) || findSpan(delimiters, position)) return [];

    const escapes = [];
    while (out[position] === '_' && !isEscaped(out, position)) {
      // A raw `_` outside the escaped text cannot be escaped here.
      if (!findSpan(textSpans, position)) return null;
      escapes.push(position);
      position += step;
    }

    return escapes.length ? escapes : null;
  };

  // A numeric character reference renders as the same character but counts as punctuation, so
  // writing the character beside a run this way lets the run open or close. Only escaped text is
  // rewritten; link targets, code, autolinks and references are left alone.
  const referenceEdit = ({ char, index }, side) => {
    if (index < 0 || edits.has(index) || !isWordCharacter(char)) return null;

    const span = findSpan(textSpans, index);
    if (!span || index + char.length > span.end) return null;
    // A backslash before the reference would escape its `&`.
    if (isEscaped(out, index) || isInUrl(index)) return null;

    const escapes = neighbourEdits(index, char.length, side);
    // An escaped `_` ends an email address or URL where the renderer would have kept going.
    if (!escapes || escapes.some((position) => isInEmail(position) || isInUrl(position)))
      return null;

    return [[index, `&#${char.codePointAt(0)};`], ...escapes.map((position) => [position, '\\_'])];
  };

  const attempt = (skippedPairs) => {
    edits = new Map();

    // 1. Write italic `_` pairs as `*` where that leaves fewer runs that cannot open or close:
    // `*` opens and closes inside words.
    const switched = italicPairs.filter((pair) => {
      if (skippedPairs.has(pair)) return false;

      const before = judge(runsOf(clustersOf(pair)));
      pair.forEach(({ start }) => edits.set(start, '*'));

      const after = judge(runsOf(clustersOf(pair)));
      if (!before.foreign.size && !after.foreign.size && after.invalid < before.invalid)
        return true;

      pair.forEach(({ start }) => edits.delete(start));
      return false;
    });

    // 2. Write the text character outside a run that still cannot open or close as a character
    // reference, where that repairs the run and leaves every other run as it was.
    const runs = runsOf(delimiters);
    const runsBeside = new Map();
    runs.forEach((run) => {
      const { before, twoBefore, after } = surroundings(run);
      [before, twoBefore, after]
        .filter(({ index }) => index >= 0)
        .forEach(({ index }) => runsBeside.set(index, [...(runsBeside.get(index) || []), run]));
    });

    const tryEdit = (changes) => {
      const affected = [...new Set(changes.flatMap(([index]) => runsBeside.get(index) || []))];
      const before = judge(affected);
      changes.forEach(([index, text]) => edits.set(index, text));

      const after = judge(affected);
      const splitsEmail = affected.some(isInsideEmail);
      if (
        !after.foreign.size &&
        !splitsEmail &&
        after.invalid < before.invalid &&
        keeps(before, after)
      )
        return;

      changes.forEach(([index]) => edits.delete(index));
    };

    runs.forEach((run) => {
      const sides = [];
      if (run.delimiters.some(({ opens }) => !opens)) sides.push('after');
      if (run.delimiters.some(({ opens }) => opens)) sides.push('before');

      sides.forEach((side) => {
        if (!isRecordedRun(run) || isValid(run)) return;

        const { before, after } = surroundings(run);
        const changes = referenceEdit(side === 'after' ? after : before, side);
        if (changes) tryEdit(changes);
      });
    });

    // A switch can merge italic into a neighbouring run that only a reference then repairs.
    // Switches whose runs end up worse than they started are dropped and the repair is redone.
    const final = judge(runsOf(delimiters));
    if (keeps(initial, final)) return [];

    const broken = [...initial.valid].filter((delimiter) => !final.valid.has(delimiter));
    const culprits = switched.filter((pair) =>
      clustersOf(pair).some(
        (delimiter) => broken.includes(delimiter) || final.foreign.has(delimiter),
      ),
    );
    return culprits.length ? culprits : switched;
  };

  const skippedPairs = new Set();
  let culprits = attempt(skippedPairs);
  while (culprits.length) {
    culprits.forEach((pair) => skippedPairs.add(pair));
    culprits = attempt(skippedPairs);
  }
  if (!keeps(initial, judge(runsOf(delimiters)))) return out;
  if (!edits.size) return out;

  const positions = [...edits.keys()].sort((a, b) => a - b);
  let result = '';
  let copied = 0;
  positions.forEach((position) => {
    result += out.slice(copied, position) + edits.get(position);
    copied = position + String.fromCodePoint(out.codePointAt(position)).length;
  });

  return result + out.slice(copied);
}

export class DelimiterAwareSerializerState extends MarkdownSerializerState {
  constructor(...args) {
    super(...args);

    this.delimiters = [];
    this.textSpans = [];
    this.pendingDelimiter = null;
    this.openPairs = {};
    this.pairCount = 0;
    this.inlineDepth = 0;
  }

  // A mark cannot nest inside itself, so its delimiters alternate between opening and closing.
  recordDelimiter(name, text) {
    const opens = !this.openPairs[name];
    if (opens) {
      this.pairCount += 1;
      this.openPairs[name] = this.pairCount;
    }

    this.pendingDelimiter = { pair: this.openPairs[name], opens, text };
    if (!opens) delete this.openPairs[name];
  }

  text(text, escape = true) {
    const pending = this.pendingDelimiter;
    const start = this.out.length;
    this.pendingDelimiter = null;

    super.text(text, escape);

    const { length } = this.out;
    const lastSpan = this.textSpans[this.textSpans.length - 1];
    if (pending && pending.text === text) {
      this.delimiters.push({ ...pending, start: length - text.length, end: length });
    } else if (escape && length > start) {
      this.textSpans.push({ start, end: length });
    } else if (text[0] === '[' && lastSpan?.end === start && this.out[start] === '!') {
      // prosemirror-markdown escapes a `!` written just before a link, which moves it one place.
      lastSpan.end += 1;
    }
  }

  renderInline(parent, fromBlockStart) {
    const firstDelimiter = this.delimiters.length;
    const firstTextSpan = this.textSpans.length;
    this.inlineDepth += 1;

    super.renderInline(parent, fromBlockStart);

    this.inlineDepth -= 1;
    this.pendingDelimiter = null;
    const delimiters = this.delimiters.splice(firstDelimiter);
    const textSpans = this.textSpans.splice(firstTextSpan);
    if (!this.inlineDepth) this.textSpans = [];

    // Positions only hold if nothing rewrote the output after the delimiter was written.
    const holds = ({ start, text }) => this.out.startsWith(text, start);
    this.out = repairDelimiters({
      out: this.out,
      delimiters: delimiters.filter(holds).sort((a, b) => a.start - b.start),
      textSpans: textSpans.sort((a, b) => a.start - b.start),
    });
  }
}

/**
 * Returns the delimiter for a mark serializer, telling the serializer state where it was
 * written so it can be repaired if it cannot open or close.
 */
export const recordDelimiter = (state, mark, text) => {
  state.recordDelimiter(mark.type.name, text);
  return text;
};
