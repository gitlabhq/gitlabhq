import {
  isEmptyPanelData,
  availableVisualizationsValidator,
  getDashboardConfig,
  getVisualizationCategory,
  parsePanelToGridItem,
  createNewVisualizationPanel,
} from '~/vue_shared/components/customizable_dashboard/utils';

import {
  CATEGORY_SINGLE_STATS,
  CATEGORY_CHARTS,
  CATEGORY_TABLES,
  DASHBOARD_SCHEMA_VERSION,
} from '~/vue_shared/components/customizable_dashboard/constants';

import { dashboard, mockPanel, createVisualization } from './mock_data';

describe('#createNewVisualizationPanel', () => {
  it('returns the expected object', () => {
    const visualization = createVisualization();
    expect(createNewVisualizationPanel(visualization)).toMatchObject({
      visualization: {
        ...visualization,
        errors: null,
      },
      title: 'Test visualization',
      gridAttributes: {
        width: 4,
        height: 3,
      },
      options: {},
    });
  });
});

describe('isEmptyPanelData', () => {
  it.each`
    visualizationType | value  | expected
    ${'SingleStat'}   | ${[]}  | ${false}
    ${'SingleStat'}   | ${1}   | ${false}
    ${'LineChart'}    | ${[]}  | ${true}
    ${'LineChart'}    | ${[1]} | ${false}
  `(
    'returns $expected for visualization "$visualizationType" with value "$value"',
    ({ visualizationType, value, expected }) => {
      const result = isEmptyPanelData(visualizationType, value);
      expect(result).toBe(expected);
    },
  );
});

describe('availableVisualizationsValidator', () => {
  it('returns true when the object contains all properties', () => {
    const result = availableVisualizationsValidator({
      loading: false,
      hasError: false,
      visualizations: [],
    });
    expect(result).toBe(true);
  });

  it.each([
    { visualizations: [] },
    { hasError: false },
    { loading: true },
    { loading: true, hasError: false },
  ])('returns false when the object does not contain all properties', (testCase) => {
    const result = availableVisualizationsValidator(testCase);
    expect(result).toBe(false);
  });
});

describe('getDashboardConfig', () => {
  it('maps dashboard to expected value', () => {
    const result = getDashboardConfig(dashboard);
    const visualization = createVisualization();

    expect(result).toMatchObject({
      id: 'analytics_overview',
      version: DASHBOARD_SCHEMA_VERSION,
      panels: [
        {
          gridAttributes: {
            height: 3,
            width: 3,
          },
          queryOverrides: {},
          title: 'Test A',
          visualization,
        },
        {
          gridAttributes: {
            height: 4,
            width: 2,
          },
          queryOverrides: {
            limit: 200,
          },
          title: 'Test B',
          visualization,
        },
      ],
      title: 'Analytics Overview',
      status: null,
      errors: null,
    });
  });

  ['userDefined', 'slug'].forEach((omitted) => {
    it(`omits "${omitted}" dashboard property`, () => {
      const result = getDashboardConfig(dashboard);

      expect(result[omitted]).not.toBeDefined();
    });
  });
});

describe('getVisualizationCategory', () => {
  it.each`
    category                 | type
    ${CATEGORY_SINGLE_STATS} | ${'SingleStat'}
    ${CATEGORY_TABLES}       | ${'DataTable'}
    ${CATEGORY_CHARTS}       | ${'LineChart'}
    ${CATEGORY_CHARTS}       | ${'FooBar'}
  `('returns $category when the visualization type is $type', ({ category, type }) => {
    expect(getVisualizationCategory({ type })).toBe(category);
  });
});

describe('parsePanelToGridItem', () => {
  it('parses all panel configs to GridStack format', () => {
    const { gridAttributes, ...rest } = mockPanel;

    expect(parsePanelToGridItem(mockPanel)).toStrictEqual({
      x: gridAttributes.xPos,
      y: gridAttributes.yPos,
      w: gridAttributes.width,
      h: gridAttributes.height,
      minH: gridAttributes.minHeight,
      minW: gridAttributes.minWidth,
      maxH: gridAttributes.maxHeight,
      maxW: gridAttributes.maxWidth,
      id: mockPanel.id,
      props: rest,
    });
  });

  it('filters out props with undefined values', () => {
    const local = { ...mockPanel };
    local.id = undefined;

    expect(Object.keys(parsePanelToGridItem(local))).not.toContain('id');
  });
});
