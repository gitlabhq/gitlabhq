import { createTestingPinia } from '@pinia/testing';
import { useViewport } from '~/pinia/global_stores/viewport';
import { getPageBreakpoints } from '~/lib/utils/css_utils';

jest.mock('~/lib/utils/css_utils');

describe('Viewport store', () => {
  let mockBreakpoints;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    jest.clearAllMocks();

    mockBreakpoints = {
      compact: { matches: false, addEventListener: jest.fn() },
      intermediate: { matches: false, addEventListener: jest.fn() },
      wide: { matches: false, addEventListener: jest.fn() },
      narrow: { matches: false, addEventListener: jest.fn() },
    };

    getPageBreakpoints.mockReturnValue(mockBreakpoints);
  });

  describe('viewport detection', () => {
    it.each([
      ['compact', 'isCompactSize'],
      ['intermediate', 'isIntermediateSize'],
      ['wide', 'isWideSize'],
      ['narrow', 'isNarrowScreen'],
    ])('detects %s viewport correctly', (breakpoint, property) => {
      mockBreakpoints[breakpoint].matches = true;

      const viewport = useViewport();
      expect(viewport[property]).toBe(true);
    });
  });

  describe('setViewportState function', () => {
    it.each`
      scenario                    | stateToSet                      | expectedState
      ${'set isNarrowScreen'}     | ${{ isNarrowScreen: true }}     | ${{ isNarrowScreen: true, isCompactSize: false, isIntermediateSize: false, isWideSize: false }}
      ${'set isCompactSize'}      | ${{ isCompactSize: true }}      | ${{ isNarrowScreen: false, isCompactSize: true, isIntermediateSize: false, isWideSize: false }}
      ${'set isIntermediateSize'} | ${{ isIntermediateSize: true }} | ${{ isNarrowScreen: false, isCompactSize: false, isIntermediateSize: true, isWideSize: false }}
      ${'set isWideSize'}         | ${{ isWideSize: true }}         | ${{ isNarrowScreen: false, isCompactSize: false, isIntermediateSize: false, isWideSize: true }}
    `('$scenario', ({ stateToSet, expectedState }) => {
      const viewport = useViewport();
      viewport.setViewportState(stateToSet);

      expect(viewport.isNarrowScreen).toBe(expectedState.isNarrowScreen);
      expect(viewport.isCompactSize).toBe(expectedState.isCompactSize);
      expect(viewport.isIntermediateSize).toBe(expectedState.isIntermediateSize);
      expect(viewport.isWideSize).toBe(expectedState.isWideSize);
    });
  });
});
