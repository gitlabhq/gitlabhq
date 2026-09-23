import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { assertProps } from 'helpers/assert_props';
import DashboardCardThumbnail from '~/vue_shared/components/dashboards_list/dashboard_card_thumbnail.vue';

describe('DashboardCardThumbnail', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findThumbnail = () => wrapper.findByTestId('dashboard-card-thumbnail');
  const findStatTiles = () => wrapper.findAllByTestId('dashboard-card-thumbnail-stat');
  const findBarsBlocks = () => wrapper.findAllByTestId('dashboard-card-thumbnail-bar-rows');
  const findTextBlocks = () => wrapper.findAllByTestId('dashboard-card-thumbnail-text-lines');
  const findLineChartTiles = () => wrapper.findAllByTestId('dashboard-card-thumbnail-line-chart');
  const findLineChartSvg = () => findLineChartTiles().at(0).find('svg');

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMountExtended(DashboardCardThumbnail, {
      propsData,
    });
  };

  // Expected values are deterministic: the layout util hashes the seed key
  // into a seeded PRNG, so a given key always yields the same wireframe. The
  // template picked per seed key is pinned in dashboard_preview_layout_spec.js.
  describe.each`
    description                         | seedKey                                        | statCount | barsCount | textCount | lineChartCount | accentClass
    ${'the "dap_impact" slug'}          | ${'dap_impact'}                                | ${2}      | ${0}      | ${1}      | ${1}           | ${'gl-bg-data-viz-orange-500'}
    ${'the "duo_and_sdlc_trends" slug'} | ${'duo_and_sdlc_trends'}                       | ${2}      | ${1}      | ${1}      | ${0}           | ${'gl-bg-data-viz-orange-500'}
    ${'a custom dashboard global id'}   | ${'gid://gitlab/Analytics::CustomDashboard/1'} | ${2}      | ${0}      | ${1}      | ${1}           | ${'gl-bg-data-viz-blue-500'}
  `(
    'with $description',
    ({ seedKey, statCount, barsCount, textCount, lineChartCount, accentClass }) => {
      beforeEach(() => {
        createWrapper({ seedKey });
      });

      it('renders the expected wireframe pieces', () => {
        expect(findStatTiles()).toHaveLength(statCount);
        expect(findBarsBlocks()).toHaveLength(barsCount);
        expect(findTextBlocks()).toHaveLength(textCount);
        expect(findLineChartTiles()).toHaveLength(lineChartCount);
      });

      it(`uses the ${accentClass} accent`, () => {
        expect(wrapper.find(`.${accentClass}`).exists()).toBe(true);
      });
    },
  );

  it('renders the same wireframe every time for the same seed key', () => {
    createWrapper({ seedKey: 'dap_impact' });
    const firstRender = wrapper.html();

    createWrapper({ seedKey: 'dap_impact' });

    expect(wrapper.html()).toBe(firstRender);
  });

  it('does not use Math.random', () => {
    const randomSpy = jest.spyOn(Math, 'random');

    createWrapper({ seedKey: 'dap_impact' });

    expect(randomSpy).not.toHaveBeenCalled();
  });

  describe('without a seed key', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('still renders a deterministic wireframe', () => {
      expect(findStatTiles()).toHaveLength(2);
      expect(findBarsBlocks()).toHaveLength(1);
      expect(findTextBlocks()).toHaveLength(1);
    });
  });

  describe('with mimic pieces', () => {
    const stat = { type: 'stat', wide: false };
    const wideBars = { type: 'bar-rows', wide: true };
    const dapImpactPieces = [stat, stat, stat, wideBars];

    it('renders the pieces instead of a seeded template', () => {
      createWrapper({
        seedKey: 'gid://gitlab/Analytics::CustomDashboard/1',
        pieces: dapImpactPieces,
      });

      expect(findStatTiles()).toHaveLength(3);
      expect(findBarsBlocks()).toHaveLength(1);
      expect(findTextBlocks()).toHaveLength(0);
      expect(findLineChartTiles()).toHaveLength(0);
    });

    it('keeps the seeded accent for the seed key', () => {
      createWrapper({ seedKey: 'dap_impact', pieces: dapImpactPieces });

      expect(wrapper.find('.gl-bg-data-viz-orange-500').exists()).toBe(true);
    });

    it('renders the same wireframe every time for the same seed key and pieces', () => {
      createWrapper({ seedKey: 'dap_impact', pieces: dapImpactPieces });
      const firstRender = wrapper.html();

      createWrapper({ seedKey: 'dap_impact', pieces: dapImpactPieces });

      expect(wrapper.html()).toBe(firstRender);
    });

    // The mimic arrangement itself (stat-row cap, wide rows, pairing, drops,
    // empty-array fallback) is pinned in dashboard_preview_layout_spec.js.
    it('renders each layout row as one child element of the thumbnail', () => {
      createWrapper({
        seedKey: 'dap_impact',
        pieces: [stat, { type: 'text-lines', wide: true }],
      });

      expect(findThumbnail().element.children).toHaveLength(2);
      expect(findStatTiles()).toHaveLength(1);
      expect(findTextBlocks()).toHaveLength(1);
    });

    it('sizes half-row pieces at gl-w-1/2 and full-row pieces with gl-flex-1', () => {
      // A lone narrow non-stat piece yields a half row below the stat row.
      createWrapper({
        seedKey: 'dap_impact',
        pieces: [stat, { type: 'text-lines', wide: false }],
      });

      expect(findStatTiles().at(0).classes()).toContain('gl-flex-1');
      expect(findTextBlocks().at(0).classes()).toContain('gl-w-1/2');
    });

    it.each(['stat', 'bar-rows', 'line-chart', 'text-lines'])('accepts a "%s" piece', (type) => {
      expect(() =>
        assertProps(DashboardCardThumbnail, { pieces: [{ type, wide: true }] }),
      ).not.toThrow();
    });

    // Vue 3 dedupes identical prop-warning messages, so only the first
    // assertProps().toThrow() in a table would throw. Keep one mount-level
    // case and assert the remaining shapes against the validator directly.
    it('rejects an unknown piece type', () => {
      expect(() =>
        assertProps(DashboardCardThumbnail, { pieces: [{ type: 'sparkline', wide: false }] }),
      ).toThrow();
    });

    it.each`
      description                  | pieces
      ${'a piece without a type'}  | ${[{ wide: true }]}
      ${'a null piece'}            | ${[null]}
      ${'a non-boolean wide flag'} | ${[{ type: 'stat', wide: 'yes' }]}
    `('fails validation for $description', ({ pieces }) => {
      expect(DashboardCardThumbnail.props.pieces.validator(pieces)).toBe(false);
    });

    it('passes validation for a well-formed piece', () => {
      expect(DashboardCardThumbnail.props.pieces.validator([{ type: 'stat', wide: true }])).toBe(
        true,
      );
    });
  });

  describe('accessibility', () => {
    beforeEach(() => {
      createWrapper({ seedKey: 'dap_impact' });
    });

    it('is decorative and hidden from screen readers', () => {
      expect(findThumbnail().attributes('aria-hidden')).toBe('true');
      expect(findLineChartSvg().attributes('role')).toBe('presentation');
    });
  });

  describe('wireframe pieces', () => {
    it('renders a stat tile as a title bar and a single accent pill', () => {
      createWrapper({ seedKey: 'dap_impact' });

      const statTile = findStatTiles().at(0);

      const [titleBar, accentPill] = statTile.element.firstElementChild.children;

      expect(statTile.element.firstElementChild.children).toHaveLength(2);
      expect([...titleBar.classList]).toContain('gl-bg-[var(--gl-border-color-default)]');
      expect([...accentPill.classList]).toContain('gl-bg-data-viz-orange-500');
    });

    it('renders three bars in a bar-rows block, coloring at least one with the accent', () => {
      createWrapper({ seedKey: 'duo_and_sdlc_trends' });

      const barsBlock = findBarsBlocks().at(0);

      const barClassLists = [...barsBlock.element.firstElementChild.children].map((bar) => [
        ...bar.classList,
      ]);

      expect(barClassLists).toHaveLength(3);
      expect(barClassLists.flat()).toContain('gl-bg-data-viz-orange-500');
      expect(barClassLists.flat()).toContain('gl-bg-[var(--gl-border-color-default)]');
    });

    it('strokes the line chart with a single accent curve over a soft area fill', () => {
      createWrapper({ seedKey: 'dap_impact' });

      const lineChart = findLineChartSvg();
      const paths = lineChart.findAll('path');

      expect(lineChart.classes()).toContain('gl-text-data-viz-orange-500');
      expect(paths).toHaveLength(2);
      expect(paths.at(0).attributes('fill')).toBe('currentColor');
      expect(paths.at(0).attributes('fill-opacity')).toBe('0.1');
      expect(paths.at(0).attributes('stroke')).toBeUndefined();
      expect(paths.at(1).attributes('stroke')).toBe('currentColor');
      expect(paths.at(1).attributes('fill')).toBe('none');
    });

    it('renders pieces directly on the surface without tile boxes', () => {
      createWrapper({ seedKey: 'dap_impact' });

      const tile = findStatTiles().at(0);

      expect(tile.classes()).not.toContain('gl-bg-subtle');
      expect(tile.classes()).not.toContain('gl-border');
    });
  });
});
