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
      ['compact', 'isCompactViewport'],
      ['intermediate', 'isIntermediateViewport'],
      ['wide', 'isWideViewport'],
      ['narrow', 'isNarrowScreen'],
    ])('detects %s viewport correctly', (breakpoint, property) => {
      mockBreakpoints[breakpoint].matches = true;

      const viewport = useViewport();
      expect(viewport[property]).toBe(true);
    });
  });

  it('updates narrow screen with updateIsNarrow', () => {
    const viewport = useViewport();

    viewport.updateIsNarrow(true);
    expect(viewport.isNarrowScreen).toBe(true);

    viewport.updateIsNarrow(false);
    expect(viewport.isNarrowScreen).toBe(false);
  });

  it('updates compact viewport with updateIsCompact', () => {
    const viewport = useViewport();

    viewport.updateIsCompact(true);
    expect(viewport.isCompactViewport).toBe(true);

    viewport.updateIsCompact(false);
    expect(viewport.isCompactViewport).toBe(false);
  });
});
