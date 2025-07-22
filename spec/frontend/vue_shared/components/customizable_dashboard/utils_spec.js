import {
  isEmptyPanelData,
  parsePanelToGridItem,
  dashboardConfigValidator,
} from '~/vue_shared/components/customizable_dashboard/utils';

import { dashboard, mockPanel } from './mock_data';

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

describe('dashboardConfigValidator', () => {
  const dashboardNoTitle = { ...dashboard, title: undefined };
  const dashboardNoDesc = { ...dashboard, description: undefined };
  const dashboardNoPanel = { ...dashboard, panels: undefined };
  const dashboardNoPanelId = { ...dashboard, panels: [{ ...mockPanel, id: undefined }] };
  const dashboardNoPanelGridAttrs = {
    ...dashboard,
    panels: [{ ...mockPanel, gridAttributes: undefined }],
  };

  it.each`
    scenario                       | config                       | expected
    ${'dashboard'}                 | ${dashboard}                 | ${true}
    ${'dashboardNoTitle'}          | ${dashboardNoTitle}          | ${true}
    ${'dashboardNoDesc'}           | ${dashboardNoDesc}           | ${true}
    ${'dashboardNoPanel'}          | ${dashboardNoPanel}          | ${true}
    ${'dashboardNoPanelId'}        | ${dashboardNoPanelId}        | ${false}
    ${'dashboardNoPanelGridAttrs'} | ${dashboardNoPanelGridAttrs} | ${false}
  `('returns $expected when config is $scenario', ({ config, scopeSlots, expected }) => {
    const result = dashboardConfigValidator(config, scopeSlots);
    expect(result).toBe(expected);
  });
});
