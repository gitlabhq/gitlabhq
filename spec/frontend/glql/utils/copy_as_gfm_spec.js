import { marked } from 'marked';
import {
  buildClipboardContent,
  writeToClipboard,
  copyGLQLNodeAsGFM,
  copyGLQLContents,
} from '~/glql/utils/copy_as_gfm';
import { DISPLAY_TYPES, DOM_COPY_DISPLAY_TYPES, DATA_COPY_DISPLAY_TYPES } from '~/glql/constants';
import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';

jest.mock('~/behaviors/markdown/copy_as_gfm', () => ({
  CopyAsGFM: { nodeToGFM: jest.fn().mockResolvedValue('mock markdown') },
}));

jest.mock('~/lib/utils/copy_to_clipboard', () => ({
  copyToClipboard: jest.fn().mockResolvedValue(),
}));

// jsdom defines neither `ClipboardItem` nor `navigator.clipboard.write`, and `restoreMocks`
// only undoes spies, so the spec puts each property's own descriptor back itself.
const CLIPBOARD_GLOBALS = [
  [window, 'isSecureContext'],
  [globalThis, 'ClipboardItem'],
  [navigator.clipboard, 'write'],
];

const describeClipboardGlobals = () => {
  let descriptors;

  beforeEach(() => {
    descriptors = CLIPBOARD_GLOBALS.map(([object, key]) =>
      Object.getOwnPropertyDescriptor(object, key),
    );
  });

  afterEach(() => {
    CLIPBOARD_GLOBALS.forEach(([object, key], index) => {
      const descriptor = descriptors[index];
      if (descriptor) Object.defineProperty(object, key, descriptor);
      else Reflect.deleteProperty(object, key);
    });
  });
};

class MockClipboardItem {
  constructor(formats) {
    this.formats = formats;
  }
}

const mockSecureContext = () => {
  Object.defineProperty(window, 'isSecureContext', { value: true, configurable: true });
  globalThis.ClipboardItem = MockClipboardItem;
  navigator.clipboard.write = jest.fn().mockResolvedValue();
};

const mockInsecureContext = () => {
  Object.defineProperty(window, 'isSecureContext', { value: false, configurable: true });
  delete globalThis.ClipboardItem;
};

// jsdom's Blob has neither `text()` nor `arrayBuffer()`.
const readBlob = (blob) =>
  new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.readAsText(blob);
  });

const writtenFormats = async () => {
  const [[items]] = navigator.clipboard.write.mock.calls;
  expect(items).toHaveLength(1);
  expect(items[0]).toBeInstanceOf(MockClipboardItem);

  const { formats } = items[0];
  expect(formats['text/html'].type).toBe('text/html');
  expect(formats['text/plain'].type).toBe('text/plain');

  return {
    html: await readBlob(formats['text/html']),
    text: await readBlob(formats['text/plain']),
  };
};

const copiedText = () => copyToClipboard.mock.calls.at(-1)[0];

const parseHtml = (html) => new DOMParser().parseFromString(html, 'text/html').body;

const tableCells = (root) =>
  [...root.querySelectorAll('tr')].map((row) =>
    [...row.querySelectorAll('th, td')].map((cell) => cell.textContent.trim()),
  );

// marked is the GFM renderer the app already ships. It has no dollar-math extension, so
// `$` escaping is asserted on the raw GFM; the server GLFM pipeline was probed separately.
const renderGfm = (markdown) => parseHtml(marked.parse(markdown, { gfm: true }));

const FORMATTING_ELEMENTS = 'em, strong, b, i, code, del, script, h1, h2, h3, ul, ol, li';

const createMockElement = () => {
  const el = document.createElement('div');
  el.innerHTML = '<span>content</span>';
  return el;
};

const LANGUAGE = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const IDE = { key: 'ideName', label: 'IDE', name: 'ideName', type: 'dimension' };
const TOTAL_COUNT = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };
const ACCEPTED_COUNT = { key: 'acceptedCount', label: 'Accepted count', type: 'metric' };
const USERS_COUNT = { key: 'usersCount', label: 'Users count', type: 'metric' };
const P50 = {
  key: 'durationQuantile',
  field: 'durationQuantile',
  label: 'Duration quantile',
  type: 'metric',
  parameters: { quantile: 0.5 },
};
const P50_ALIASED = { ...P50, key: 'p50', label: 'p50' };
const bucket = (granularity, key = 'created', label = 'Created') => ({
  key,
  field: 'created',
  label,
  type: 'dimension',
  parameters: { granularity },
});

// The locale range formatter pads the en dash with thin spaces.
const range = (start, end) => `${start}\u2009\u2013\u2009${end}`;

const LITERAL_STRINGS = [
  'Count <threshold>',
  '<script>alert("xss")</script>',
  '<b>bold</b> "quoted" \'single\'',
  '_private_ __total__',
  'code_review/v1',
  '&copy; &#124; A & B',
  '`code` **bold** ~~gone~~',
  '[link](http://x)',
  'A|B',
  'a\\|b C:\\path',
  '-5 or 3.75',
];

describe('buildClipboardContent', () => {
  it('builds a GFM table and an HTML table with the same headers and rows', () => {
    const nodes = [
      { language: 'ruby', totalCount: 21, acceptedCount: 15, usersCount: 5 },
      { language: 'python', totalCount: 14, acceptedCount: 8, usersCount: 3 },
    ];

    const { html, text } = buildClipboardContent(nodes, [
      LANGUAGE,
      TOTAL_COUNT,
      ACCEPTED_COUNT,
      USERS_COUNT,
    ]);

    expect(text).toBe(
      [
        '| Language | Total count | Accepted count | Users count |',
        '| --- | --- | --- | --- |',
        '| ruby | 21 | 15 | 5 |',
        '| python | 14 | 8 | 3 |',
      ].join('\n'),
    );
    expect(html).toMatch(
      /^<table><thead><tr>(<th>.*<\/th>)+<\/tr><\/thead><tbody>.*<\/tbody><\/table>$/,
    );
    expect(tableCells(parseHtml(html))).toEqual([
      ['Language', 'Total count', 'Accepted count', 'Users count'],
      ['ruby', '21', '15', '5'],
      ['python', '14', '8', '3'],
    ]);
  });

  it('copies an empty result as a header-only table in both formats', () => {
    const { html, text } = buildClipboardContent([], [LANGUAGE, TOTAL_COUNT]);

    expect(text).toBe('| Language | Total count |\n| --- | --- |');
    expect(html).toBe(
      '<table><thead><tr><th>Language</th><th>Total count</th></tr></thead><tbody></tbody></table>',
    );
  });

  it('appends parameters to unaliased headers and keeps alias labels as-is', () => {
    const { text } = buildClipboardContent([], [bucket('weekly'), P50, P50_ALIASED]);

    expect(text.split('\n')[0]).toBe('| Created (weekly) | Duration quantile (0.5) | p50 |');
  });

  it('copies the label the chart shows for an object dimension, not its JSON', () => {
    const AUTHOR = { key: 'user', label: 'User', type: 'dimension' };
    const nodes = [
      { user: { __typename: 'UserCore', name: 'Jane Doe', username: 'jane' }, totalCount: 2 },
      { user: { __typename: 'UserCore', username: 'anon' }, totalCount: 1 },
      { user: null, totalCount: 4 },
    ];

    const { text } = buildClipboardContent(nodes, [AUTHOR, TOTAL_COUNT]);

    expect(text.split('\n').slice(2)).toEqual([
      '| Jane Doe | 2 |',
      '| anon | 1 |',
      '| Unknown | 4 |',
    ]);
  });

  it('formats metrics by the unit of their base field, missing values as zero, unknown units raw', () => {
    const RATE = { key: 'rate', field: 'acceptanceRate', label: 'Rate', type: 'metric' };
    const SHOWN = { key: 'shown', field: 'shownCount', label: 'Shown', type: 'metric' };
    const SCORE = { key: 'score', label: 'Score', type: 'metric' };
    const nodes = [
      { language: 'ruby', p50: 90, rate: 0.5, shown: 1234, score: 3.75 },
      { language: 'go' },
    ];

    const { text } = buildClipboardContent(nodes, [LANGUAGE, P50_ALIASED, RATE, SHOWN, SCORE]);

    expect(text.split('\n').slice(2)).toEqual([
      '| ruby | 1m 30s | 50% | 1,234 | 3.75 |',
      '| go | 0s | 0% | 0 | 0 |',
    ]);
  });

  describe('date bucket dimensions', () => {
    it.each`
      granularity  | series                                              | labels
      ${'daily'}   | ${['2026-01-12T00:00:00Z', '2026-01-13T00:00:00Z']} | ${['Jan 12, 2026', 'Jan 13, 2026']}
      ${'daily'}   | ${['2025-12-31T00:00:00Z', '2026-01-01T00:00:00Z']} | ${['Dec 31, 2025', 'Jan 1, 2026']}
      ${'weekly'}  | ${['2026-01-12', '2026-01-19']}                     | ${[range('Jan 12', '18, 2026'), range('Jan 19', '25, 2026')]}
      ${'weekly'}  | ${['2025-12-29', '2026-01-05']}                     | ${[range('Dec 29, 2025', 'Jan 4, 2026'), range('Jan 5', '11, 2026')]}
      ${'monthly'} | ${['2026-01-01', '2026-02-01']}                     | ${['Jan 2026', 'Feb 2026']}
      ${'monthly'} | ${['2025-12-01', '2026-01-01']}                     | ${['Dec 2025', 'Jan 2026']}
    `('copies a $granularity series $series with the year', ({ granularity, series, labels }) => {
      const nodes = series.map((created, i) => ({ created, totalCount: i + 1 }));

      const { text } = buildClipboardContent(nodes, [bucket(granularity), TOTAL_COUNT]);

      expect(text.split('\n').slice(2)).toEqual(
        labels.map((label, i) => `| ${label} | ${i + 1} |`),
      );
    });

    it('formats an aliased date dimension by its granularity under the alias header', () => {
      const nodes = [{ Week: '2026-01-12', totalCount: 3 }];

      const { text } = buildClipboardContent(nodes, [
        bucket('weekly', 'Week', 'Week'),
        TOTAL_COUNT,
      ]);

      expect(text).toBe(
        `| Week | Total count |\n| --- | --- |\n| ${range('Jan 12', '18, 2026')} | 3 |`,
      );
    });

    it('leaves dimensions without a granularity unformatted', () => {
      const { text } = buildClipboardContent(
        [{ language: '2026-01-12', totalCount: 3 }],
        [LANGUAGE, TOTAL_COUNT],
      );

      expect(text.split('\n')[2]).toBe('| 2026-01-12 | 3 |');
    });
  });

  describe('literal text', () => {
    const NAME = { key: 'name', label: 'Name', type: 'dimension' };

    it.each(LITERAL_STRINGS)('round-trips %p through both formats as inert text', (value) => {
      const { html, text } = buildClipboardContent(
        [{ name: value, totalCount: 1 }],
        [{ ...NAME, label: value }, TOTAL_COUNT],
      );

      const expected = [
        [value, 'Total count'],
        [value, '1'],
      ];
      const rendered = renderGfm(text);
      expect(tableCells(rendered)).toEqual(expected);
      expect(rendered.querySelector(FORMATTING_ELEMENTS)).toBe(null);
      expect(tableCells(parseHtml(html))).toEqual(expected);
      expect(parseHtml(html).querySelector(FORMATTING_ELEMENTS)).toBe(null);
    });

    it('escapes dollar signs so GLFM does not read them as math', () => {
      const { text } = buildClipboardContent(
        [{ name: '$x$ costs $5', totalCount: 1 }],
        [NAME, TOTAL_COUNT],
      );

      expect(text.split('\n')[2]).toBe('| \\$x\\$ costs \\$5 | 1 |');
    });

    it.each`
      value               | cell
      ${'line1\nline2'}   | ${'line1 line2'}
      ${'line1\r\nline2'} | ${'line1 line2'}
      ${'a\n\n\nb'}       | ${'a b'}
      ${'A|B\nC'}         | ${'A\\|B C'}
    `('collapses newlines in $value to keep the GFM row intact', ({ value, cell }) => {
      const { text } = buildClipboardContent([{ name: value, totalCount: 1 }], [NAME, TOTAL_COUNT]);

      expect(text.split('\n')[2]).toBe(`| ${cell} | 1 |`);
    });
  });
});

describe('writeToClipboard', () => {
  describeClipboardGlobals();

  it('writes html and text as the two formats of one ClipboardItem in a secure context', async () => {
    mockSecureContext();

    await writeToClipboard('<b>html</b>', 'plain text');

    expect(await writtenFormats()).toEqual({ html: '<b>html</b>', text: 'plain text' });
    expect(copyToClipboard).not.toHaveBeenCalled();
  });

  it('falls back to copyToClipboard with plain text in an insecure context', async () => {
    mockInsecureContext();

    await writeToClipboard('<b>html</b>', 'plain text');

    expect(copyToClipboard).toHaveBeenCalledWith('plain text');
  });

  it('falls back to copyToClipboard when ClipboardItem is not defined', async () => {
    Object.defineProperty(window, 'isSecureContext', { value: true, configurable: true });
    delete globalThis.ClipboardItem;

    await writeToClipboard('<b>html</b>', 'plain text');

    expect(copyToClipboard).toHaveBeenCalledWith('plain text');
  });
});

describe('copyGLQLNodeAsGFM', () => {
  describeClipboardGlobals();

  it('writes a clone of the element with dates expanded, and its markdown', async () => {
    mockSecureContext();
    const el = createMockElement();
    el.innerHTML = '<time title="Jan 1, 2026">1 day ago</time>';

    await copyGLQLNodeAsGFM(el);

    expect(CopyAsGFM.nodeToGFM).toHaveBeenCalledWith(el);
    expect(await writtenFormats()).toEqual({
      html: '<div><time title="Jan 1, 2026">Jan 1, 2026</time></div>',
      text: 'mock markdown',
    });
    expect(el.innerHTML).toBe('<time title="Jan 1, 2026">1 day ago</time>');
  });

  it('prepends a given label to both formats', async () => {
    mockSecureContext();

    await copyGLQLNodeAsGFM(createMockElement(), { label: 'Duration quantile (0.5)' });

    expect(await writtenFormats()).toEqual({
      html: '<p>Duration quantile (0.5)</p><div><span>content</span></div>',
      text: 'Duration quantile (0.5)\n\nmock markdown',
    });
  });

  it('falls back to copyToClipboard with the labelled markdown in an insecure context', async () => {
    mockInsecureContext();

    await copyGLQLNodeAsGFM(createMockElement(), { label: 'Total count' });

    expect(copyToClipboard).toHaveBeenCalledWith('Total count\n\nmock markdown');
  });
});

const ONE_ROW = [{ language: 'ruby', totalCount: 21 }];
const SIMPLE_CHART = {
  strategy: 'data',
  fields: [LANGUAGE, TOTAL_COUNT],
  nodes: ONE_ROW,
  expected: '| Language | Total count |\n| --- | --- |\n| ruby | 21 |',
};

const COPY_CASES = {
  list: { strategy: 'dom', fields: [LANGUAGE, TOTAL_COUNT], nodes: ONE_ROW },
  orderedList: { strategy: 'dom', fields: [LANGUAGE, TOTAL_COUNT], nodes: ONE_ROW },
  table: { strategy: 'dom', fields: [LANGUAGE, TOTAL_COUNT], nodes: ONE_ROW },
  stat: {
    strategy: 'dom',
    fields: [P50],
    nodes: [{ durationQuantile: 90 }],
    label: 'Duration quantile (0.5)',
  },
  columnChart: SIMPLE_CHART,
  lineChart: SIMPLE_CHART,
  barChart: SIMPLE_CHART,
  areaChart: SIMPLE_CHART,
  barList: {
    strategy: 'data',
    fields: [LANGUAGE, TOTAL_COUNT],
    nodes: [...ONE_ROW, { language: 'go', totalCount: 4 }],
    expected: '| Language | Total count |\n| --- | --- |\n| ruby | 21 |\n| go | 4 |',
  },
  heatMap: {
    strategy: 'data',
    fields: [LANGUAGE, IDE, TOTAL_COUNT],
    nodes: [
      { language: 'ruby', ideName: 'vscode', totalCount: 21 },
      { language: 'ruby', ideName: 'vim', totalCount: 2 },
    ],
    expected:
      '| Language | IDE | Total count |\n| --- | --- | --- |\n| ruby | vscode | 21 |\n| ruby | vim | 2 |',
  },
  divergingBarChart: {
    strategy: 'data',
    fields: [LANGUAGE, ACCEPTED_COUNT, USERS_COUNT],
    nodes: [{ language: 'ruby', acceptedCount: 15, usersCount: 5 }],
    expected: '| Language | Accepted count | Users count |\n| --- | --- | --- |\n| ruby | 15 | 5 |',
  },
};

describe('copyGLQLContents', () => {
  describeClipboardGlobals();
  beforeEach(mockInsecureContext);

  const copy = ({ display, displayConfig, fields, nodes, el = createMockElement() }) =>
    copyGLQLContents({
      config: { display, displayConfig },
      data: { count: nodes.length, nodes },
      fields,
      el,
    });

  it('classifies every display type in exactly one copy set', () => {
    const classified = [...DOM_COPY_DISPLAY_TYPES, ...DATA_COPY_DISPLAY_TYPES];

    expect(classified).toHaveLength(new Set(classified).size);
    expect(classified.sort()).toEqual(Object.values(DISPLAY_TYPES).sort());
  });

  it('has a copy case for every display type', () => {
    expect(Object.keys(COPY_CASES).sort()).toEqual(Object.values(DISPLAY_TYPES).sort());
  });

  describe.each(Object.entries(COPY_CASES))('for a %s', (display, testCase) => {
    const { strategy, fields, nodes, expected, label } = testCase;
    let el;

    beforeEach(async () => {
      el = createMockElement();

      await copy({ display, fields, nodes, el });
    });

    if (strategy === 'data') {
      it('copies a table built from the query result', () => {
        expect(copiedText()).toBe(expected);
        expect(CopyAsGFM.nodeToGFM).not.toHaveBeenCalled();
      });
    } else {
      it('copies the rendered DOM, so the copy keeps the order and columns on screen', () => {
        expect(CopyAsGFM.nodeToGFM).toHaveBeenCalledWith(el);
        expect(copiedText()).toBe(label ? `${label}\n\nmock markdown` : 'mock markdown');
      });
    }
  });

  it('copies a barList without a dimension as one row with a column per metric', async () => {
    await copy({
      display: 'barList',
      fields: [ACCEPTED_COUNT, USERS_COUNT],
      nodes: [{ acceptedCount: 15, usersCount: 5 }],
    });

    expect(copiedText()).toBe('| Accepted count | Users count |\n| --- | --- |\n| 15 | 5 |');
  });

  it.each(['list', 'columnChart'])(
    'copies the rendered DOM for a %s without dimension or metric fields',
    async (display) => {
      await copy({
        display,
        fields: [{ key: 'title', label: 'Title', name: 'title' }],
        nodes: [{ id: 1 }],
      });

      expect(copiedText()).toBe('mock markdown');
    },
  );

  it('throws for a display type in neither copy set instead of guessing', async () => {
    await expect(copy({ display: 'sparkline', ...SIMPLE_CHART })).rejects.toThrow(
      'No copy strategy for GLQL display type "sparkline"',
    );

    expect(copyToClipboard).not.toHaveBeenCalled();
  });

  describe('stat title', () => {
    const copyStat = (displayConfig) =>
      copy({ display: 'stat', displayConfig, fields: [P50], nodes: [{ durationQuantile: 90 }] });

    it.each([undefined, { title: '' }])(
      'prepends the metric label when the block configures %p',
      async (displayConfig) => {
        await copyStat(displayConfig);

        expect(copiedText()).toBe('Duration quantile (0.5)\n\nmock markdown');
      },
    );

    // The presenter stringifies a scalar title, so a YAML-authored `title: 0` still renders.
    it.each(['Median pipeline duration', 0])(
      'copies the rendered DOM alone when the block configures the title %p',
      async (title) => {
        await copyStat({ title });

        expect(copiedText()).toBe('mock markdown');
      },
    );
  });

  describe('in a secure context', () => {
    beforeEach(mockSecureContext);

    it.each(LITERAL_STRINGS)(
      'writes a chart cell %p as inert text in both formats',
      async (value) => {
        await copy({
          display: 'columnChart',
          fields: [LANGUAGE, TOTAL_COUNT],
          nodes: [{ language: value, totalCount: 21 }],
        });

        const { html, text } = await writtenFormats();
        const expected = [
          ['Language', 'Total count'],
          [value, '21'],
        ];
        expect(tableCells(renderGfm(text))).toEqual(expected);
        expect(renderGfm(text).querySelector(FORMATTING_ELEMENTS)).toBe(null);
        expect(tableCells(parseHtml(html))).toEqual(expected);
        expect(copyToClipboard).not.toHaveBeenCalled();
      },
    );

    it.each([
      'Count <threshold>',
      '**Count** &copy;',
      '_users_ $5',
      '# Count',
      '- Count',
      '+ Count',
      '1. Count',
      '1) Count',
      '2026 sessions',
    ])('writes the stat label %p as one inert paragraph in both formats', async (label) => {
      await copy({
        display: 'stat',
        fields: [{ ...TOTAL_COUNT, label }],
        nodes: [{ totalCount: 21 }],
      });

      const { html, text } = await writtenFormats();
      const rendered = renderGfm(text);
      expect([...rendered.querySelectorAll('p')].map((p) => p.textContent)).toEqual([
        label,
        'mock markdown',
      ]);
      expect(rendered.querySelector(FORMATTING_ELEMENTS)).toBe(null);
      expect(parseHtml(html).querySelector('p').textContent).toBe(label);
      expect(parseHtml(html).querySelector(FORMATTING_ELEMENTS)).toBe(null);
    });
  });
});
