import {
  configToPreviewPieces,
  buildThumbnailLayout,
} from '~/vue_shared/components/dashboards_list/dashboard_preview_layout';

const panel = ({ type = 'SingleStat', yPos = 0, xPos = 0, width = 4, glql = null } = {}) => ({
  title: 'Panel',
  visualization: {
    type,
    data: glql ? { type: 'glql', query: { glql } } : { type: 'value_stream', query: {} },
    options: {},
  },
  gridAttributes: { yPos, xPos, width, height: 1 },
});

// The shipped system dashboard YAMLs are asserted against for real in
// ee/spec/frontend/vue_shared/components/dashboards_list/dashboard_preview_layout_spec.js.
describe('configToPreviewPieces', () => {
  it('falls back to the first view panels when the top-level panels are empty', () => {
    const config = {
      panels: [],
      views: [
        {
          title: 'Overview',
          panels: [
            panel({ type: 'SingleStat', yPos: 0, xPos: 0, width: 3 }),
            panel({ type: 'Glql', yPos: 1, xPos: 0, width: 12, glql: 'display: barList' }),
          ],
        },
        { title: 'Work', panels: [] },
      ],
    };

    expect(configToPreviewPieces(config)).toEqual([
      { type: 'stat', wide: false },
      { type: 'bar-rows', wide: true },
    ]);
  });

  it('sorts panels into reading order (yPos, then xPos) before taking pieces', () => {
    const config = {
      panels: [
        panel({ type: 'BarChart', yPos: 4, xPos: 0, width: 6 }),
        panel({ type: 'DataTable', yPos: 0, xPos: 6, width: 6 }),
        panel({ type: 'SingleStat', yPos: 0, xPos: 0, width: 6 }),
      ],
    };

    expect(configToPreviewPieces(config)).toEqual([
      { type: 'stat', wide: false },
      { type: 'text-lines', wide: false },
      { type: 'bar-rows', wide: false },
    ]);
  });

  describe('visualization type mapping', () => {
    it.each`
      visualizationType       | pieceType
      ${'SingleStat'}         | ${'stat'}
      ${'LineChart'}          | ${'line-chart'}
      ${'AreaChart'}          | ${'line-chart'}
      ${'BarChart'}           | ${'bar-rows'}
      ${'ColumnChart'}        | ${'bar-rows'}
      ${'StackedColumnChart'} | ${'bar-rows'}
      ${'DataTable'}          | ${'text-lines'}
      ${'AiImpactTable'}      | ${'text-lines'}
      ${'UsageOverview'}      | ${'text-lines'}
      ${'SomeFutureChart'}    | ${'text-lines'}
    `(
      'maps a $visualizationType panel to a $pieceType piece',
      ({ visualizationType, pieceType }) => {
        const config = { panels: [panel({ type: visualizationType })] };

        expect(configToPreviewPieces(config)).toEqual([{ type: pieceType, wide: false }]);
      },
    );

    it('maps a string visualization reference to a text-lines piece', () => {
      const config = {
        panels: [{ title: 'Panel', visualization: 'some_saved_visualization', gridAttributes: {} }],
      };

      expect(configToPreviewPieces(config)).toEqual([{ type: 'text-lines', wide: true }]);
    });
  });

  describe('Glql display mapping', () => {
    it.each`
      display                | pieceType
      ${'stat'}              | ${'stat'}
      ${'barChart'}          | ${'bar-rows'}
      ${'columnChart'}       | ${'bar-rows'}
      ${'barList'}           | ${'bar-rows'}
      ${'divergingBarChart'} | ${'bar-rows'}
      ${'lineChart'}         | ${'line-chart'}
      ${'areaChart'}         | ${'line-chart'}
      ${'table'}             | ${'text-lines'}
      ${'heatMap'}           | ${'text-lines'}
    `('maps a Glql panel displaying $display to a $pieceType piece', ({ display, pieceType }) => {
      const config = {
        panels: [panel({ type: 'Glql', glql: `display: ${display}\nmode: analytics` })],
      };

      expect(configToPreviewPieces(config)).toEqual([{ type: pieceType, wide: false }]);
    });

    it('maps a Glql panel without a display line to a text-lines piece', () => {
      const config = { panels: [panel({ type: 'Glql', glql: 'mode: analytics' })] };

      expect(configToPreviewPieces(config)).toEqual([{ type: 'text-lines', wide: false }]);
    });
  });

  describe('wide flag', () => {
    it.each`
      width | wide
      ${12} | ${true}
      ${8}  | ${true}
      ${7}  | ${false}
      ${3}  | ${false}
    `('marks a panel of width $width as wide: $wide', ({ width, wide }) => {
      const config = { panels: [panel({ width })] };

      expect(configToPreviewPieces(config)).toEqual([{ type: 'stat', wide }]);
    });

    it('treats a panel without a declared width as wide', () => {
      const widthlessPanel = { ...panel(), gridAttributes: { yPos: 0, xPos: 0, height: 1 } };

      expect(configToPreviewPieces({ panels: [widthlessPanel] })).toEqual([
        { type: 'stat', wide: true },
      ]);
    });
  });

  describe('two-row arrangement', () => {
    it('returns only the pieces that fit the two-row arrangement', () => {
      const config = {
        panels: Array.from({ length: 3 }, (_, index) =>
          panel({ type: 'DataTable', yPos: index, width: 12 }),
        ),
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'text-lines', wide: true },
        { type: 'text-lines', wide: true },
      ]);
    });

    it('keeps a leading stat row plus one more row', () => {
      const config = {
        panels: [
          ...Array.from({ length: 3 }, (_, index) =>
            panel({ type: 'SingleStat', yPos: 0, xPos: index * 4 }),
          ),
          panel({ type: 'DataTable', yPos: 1, width: 12 }),
          panel({ type: 'DataTable', yPos: 2, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
        { type: 'text-lines', wide: true },
      ]);
    });
  });

  describe('chart-diversity bias', () => {
    it('swaps the last text-lines piece for a chart found below the fold, keeping the chart panel wide flag', () => {
      const config = {
        panels: [
          panel({ type: 'SingleStat', yPos: 0 }),
          panel({ type: 'DataTable', yPos: 1, width: 12 }),
          // Below the two-row fold, but within the 10-panel scan.
          panel({ type: 'SingleStat', yPos: 2 }),
          panel({ type: 'DataTable', yPos: 3, width: 12 }),
          panel({ type: 'BarChart', yPos: 4, width: 4 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'stat', wide: false },
        { type: 'bar-rows', wide: false },
      ]);
    });

    it('swaps the last piece for a chart found below the fold when no text-lines piece exists', () => {
      const config = {
        panels: [
          ...Array.from({ length: 4 }, (_, index) =>
            panel({ type: 'SingleStat', yPos: index, width: 4 }),
          ),
          panel({ type: 'LineChart', yPos: 10, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
        { type: 'line-chart', wide: true },
      ]);
    });

    it('applies the bias to the pieces that fit the arrangement, so the chart always renders', () => {
      // Wide tables fill both rows before the piece cap is reached; the chart
      // must replace a piece that stays in frame, not one already dropped.
      const config = {
        panels: [
          ...Array.from({ length: 3 }, (_, index) =>
            panel({ type: 'DataTable', yPos: index, width: 12 }),
          ),
          panel({ type: 'SingleStat', yPos: 3 }),
          panel({ type: 'LineChart', yPos: 4, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'text-lines', wide: true },
        { type: 'line-chart', wide: true },
      ]);
    });

    it("keeps the outgoing piece's width when the chart's own width would evict an in-frame piece", () => {
      // Swapping the wide BarChart in at its real width would repack the rows
      // and drop the trailing stat; the bias must keep all four pieces.
      const config = {
        panels: [
          panel({ type: 'SingleStat', yPos: 0, xPos: 0 }),
          panel({ type: 'SingleStat', yPos: 0, xPos: 4 }),
          panel({ type: 'DataTable', yPos: 1, xPos: 0, width: 4 }),
          panel({ type: 'SingleStat', yPos: 1, xPos: 4 }),
          panel({ type: 'BarChart', yPos: 2, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
        { type: 'bar-rows', wide: false },
        { type: 'stat', wide: false },
      ]);
    });

    it("keeps the outgoing piece's width when the chart's own width would push it past the row cap", () => {
      const config = {
        panels: [
          panel({ type: 'DataTable', yPos: 0, width: 12 }),
          panel({ type: 'SingleStat', yPos: 1, xPos: 0, width: 4 }),
          panel({ type: 'DataTable', yPos: 1, xPos: 4, width: 4 }),
          panel({ type: 'LineChart', yPos: 2, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'text-lines', wide: true },
        { type: 'stat', wide: false },
        { type: 'line-chart', wide: false },
      ]);
    });

    it('leaves a dashboard with no charts anywhere unchanged', () => {
      const config = {
        panels: [
          panel({ type: 'SingleStat', yPos: 0 }),
          panel({ type: 'DataTable', yPos: 1, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'stat', wide: false },
        { type: 'text-lines', wide: true },
      ]);
    });

    it('leaves a dashboard already previewing a chart unchanged', () => {
      const config = {
        panels: [
          panel({ type: 'LineChart', yPos: 0, width: 12 }),
          panel({ type: 'DataTable', yPos: 1, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual([
        { type: 'line-chart', wide: true },
        { type: 'text-lines', wide: true },
      ]);
    });

    it('ignores charts beyond the first ten panels in reading order', () => {
      const config = {
        panels: [
          ...Array.from({ length: 4 }, (_, index) =>
            panel({ type: 'SingleStat', yPos: index, width: 4 }),
          ),
          ...Array.from({ length: 6 }, (_, index) =>
            panel({ type: 'DataTable', yPos: 4 + index, width: 12 }),
          ),
          panel({ type: 'LineChart', yPos: 20, width: 12 }),
        ],
      };

      expect(configToPreviewPieces(config)).toEqual(
        Array.from({ length: 4 }, () => ({ type: 'stat', wide: false })),
      );
    });
  });

  it('skips section headings, which have no visualization', () => {
    const config = {
      panels: [
        { section: { title: 'Users' }, gridAttributes: { yPos: 0, xPos: 0, height: 7 } },
        panel({ type: 'SingleStat', yPos: 7 }),
      ],
    };

    expect(configToPreviewPieces(config)).toEqual([{ type: 'stat', wide: false }]);
  });

  describe('maxPieces', () => {
    const eightStatsConfig = () => ({
      panels: Array.from({ length: 8 }, (_, index) =>
        panel({ type: 'SingleStat', yPos: index, width: 4 }),
      ),
    });

    it('caps the pieces at 4 by default', () => {
      expect(configToPreviewPieces(eightStatsConfig())).toHaveLength(4);
    });

    it('caps the pieces at the given maximum', () => {
      expect(configToPreviewPieces(eightStatsConfig(), { maxPieces: 2 })).toEqual([
        { type: 'stat', wide: false },
        { type: 'stat', wide: false },
      ]);
    });
  });

  describe('with no usable panels', () => {
    it.each`
      description                                       | config
      ${'a null config'}                                | ${null}
      ${'an undefined config'}                          | ${undefined}
      ${'an empty object'}                              | ${{}}
      ${'empty panels and no views'}                    | ${{ panels: [] }}
      ${'a non-array panels value'}                     | ${{ panels: 'nope' }}
      ${'empty panels and empty views'}                 | ${{ panels: [], views: [] }}
      ${'empty panels on the first view'}               | ${{ panels: [], views: [{ panels: [] }] }}
      ${'only section headings'}                        | ${{ panels: [{ section: { title: 'Users' } }] }}
      ${'a string config (config is always an object)'} | ${'{"panels": []}'}
      ${'a non-object scalar'}                          | ${42}
    `('returns null for $description', ({ config }) => {
      expect(configToPreviewPieces(config)).toBe(null);
    });
  });
});

describe('buildThumbnailLayout', () => {
  const stat = { type: 'stat', wide: false };
  const pieceTypes = (row) => row.pieces.map(({ type }) => type);

  // Expected values are deterministic: the seed key is hashed into a seeded
  // PRNG, so a given key always yields the same wireframe. The two system
  // dashboard slugs are pinned to their reference compositions.
  describe.each`
    description                         | seedKey                                        | template              | accentBar
    ${'no seed key'}                    | ${''}                                          | ${'stats-bars-text'}  | ${'gl-bg-data-viz-green-500'}
    ${'the "dap_impact" slug'}          | ${'dap_impact'}                                | ${'stats-text-chart'} | ${'gl-bg-data-viz-orange-500'}
    ${'the "duo_and_sdlc_trends" slug'} | ${'duo_and_sdlc_trends'}                       | ${'stats-bars-text'}  | ${'gl-bg-data-viz-orange-500'}
    ${'a custom dashboard global id'}   | ${'gid://gitlab/Analytics::CustomDashboard/1'} | ${'stats-text-chart'} | ${'gl-bg-data-viz-blue-500'}
  `('with $description', ({ seedKey, template, accentBar }) => {
    it(`picks the "${template}" template and the ${accentBar} accent`, () => {
      const layout = buildThumbnailLayout({ seedKey });

      expect(layout.templateName).toBe(template);
      expect(layout.accent.bar).toBe(accentBar);
    });
  });

  it('returns the same layout every time for the same seed key', () => {
    expect(buildThumbnailLayout({ seedKey: 'dap_impact' })).toEqual(
      buildThumbnailLayout({ seedKey: 'dap_impact' }),
    );
  });

  it('returns different templates or accents across seed keys', () => {
    const layouts = ['dap_impact', 'duo_and_sdlc_trends', 'vulnerabilities'].map((seedKey) =>
      buildThumbnailLayout({ seedKey }),
    );

    expect(new Set(layouts.map(({ templateName }) => templateName)).size).toBeGreaterThan(1);
  });

  describe('with mimic pieces', () => {
    it('uses the mimic template and keeps the seeded accent', () => {
      const layout = buildThumbnailLayout({ seedKey: 'dap_impact', pieces: [stat] });

      expect(layout.templateName).toBe('mimic');
      expect(layout.accent).toEqual(buildThumbnailLayout({ seedKey: 'dap_impact' }).accent);
    });

    it('puts the leading run of stats (capped at three) on a top row', () => {
      const layout = buildThumbnailLayout({
        seedKey: 'dap_impact',
        pieces: [stat, stat, stat, stat, stat],
      });

      expect(layout.rows).toHaveLength(2);
      expect(pieceTypes(layout.rows[0])).toEqual(['stat', 'stat', 'stat']);
      expect(layout.rows[0]).toMatchObject({ grow: false, half: false });
      expect(pieceTypes(layout.rows[1])).toEqual(['stat', 'stat']);
    });

    it('gives a wide piece a full-width row and keeps a lone narrow piece at half width', () => {
      const layout = buildThumbnailLayout({
        seedKey: 'dap_impact',
        pieces: [
          { type: 'text-lines', wide: true },
          { type: 'line-chart', wide: false },
        ],
      });

      expect(layout.rows).toHaveLength(2);
      expect(layout.rows[0]).toMatchObject({ grow: true, half: false });
      expect(pieceTypes(layout.rows[0])).toEqual(['text-lines']);
      expect(layout.rows[1]).toMatchObject({ grow: true, half: true });
      expect(pieceTypes(layout.rows[1])).toEqual(['line-chart']);
    });

    it('pairs two narrow pieces into a single row', () => {
      const layout = buildThumbnailLayout({
        seedKey: 'dap_impact',
        pieces: [
          { type: 'line-chart', wide: false },
          { type: 'text-lines', wide: false },
        ],
      });

      expect(layout.rows).toHaveLength(1);
      expect(pieceTypes(layout.rows[0])).toEqual(['line-chart', 'text-lines']);
    });

    it('drops pieces that would need more rows than the thumbnail can fit', () => {
      const layout = buildThumbnailLayout({
        seedKey: 'dap_impact',
        pieces: Array.from({ length: 4 }, () => ({ type: 'text-lines', wide: true })),
      });

      expect(layout.rows).toHaveLength(2);
      expect(layout.rows.flatMap(pieceTypes)).toEqual(['text-lines', 'text-lines']);
    });

    it('falls back to the seeded template when pieces is an empty array', () => {
      expect(buildThumbnailLayout({ seedKey: 'dap_impact', pieces: [] })).toEqual(
        buildThumbnailLayout({ seedKey: 'dap_impact' }),
      );
    });
  });
});
