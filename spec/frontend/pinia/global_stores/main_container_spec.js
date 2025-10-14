import { createTestingPinia } from '@pinia/testing';
import { useMainContainer } from '~/pinia/global_stores/main_container';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';

jest.mock('~/panel_breakpoint_instance');

describe('Main container store', () => {
  let mockGetBreakpointSize;
  let mockAddResizeListener;
  let mockRemoveResizeListener;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    jest.clearAllMocks();

    mockGetBreakpointSize = jest.fn();
    mockAddResizeListener = jest.fn();
    mockRemoveResizeListener = jest.fn();

    PanelBreakpointInstance.getBreakpointSize = mockGetBreakpointSize;
    PanelBreakpointInstance.addResizeListener = mockAddResizeListener;
    PanelBreakpointInstance.removeResizeListener = mockRemoveResizeListener;
  });

  describe('container size detection', () => {
    it.each([
      ['xs', 'isCompact'],
      ['sm', 'isCompact'],
      ['md', 'isIntermediate'],
      ['lg', 'isIntermediate'],
      ['xl', 'isWide'],
    ])('detects %s breakpoint correctly', (breakpoint, property) => {
      mockGetBreakpointSize.mockReturnValue(breakpoint);

      const mainContainer = useMainContainer();

      expect(mainContainer[property]).toBe(true);

      // Verify the other properties are false
      const properties = ['isCompact', 'isIntermediate', 'isWide'];
      properties.forEach((prop) => {
        if (prop !== property) {
          expect(mainContainer[prop]).toBe(false);
        }
      });
    });
  });

  describe('resize listener', () => {
    it('registers resize listener on store initialization', () => {
      mockGetBreakpointSize.mockReturnValue('md');

      useMainContainer();

      expect(mockAddResizeListener).toHaveBeenCalledWith(expect.any(Function));
    });

    it('updates values when resize listener is triggered', () => {
      mockGetBreakpointSize.mockReturnValue('xs');

      const mainContainer = useMainContainer();

      expect(mainContainer.isCompact).toBe(true);
      expect(mainContainer.isIntermediate).toBe(false);
      expect(mainContainer.isWide).toBe(false);

      // Simulate a resize event by changing the breakpoint and calling the listener
      mockGetBreakpointSize.mockReturnValue('xl');
      const resizeCallback = mockAddResizeListener.mock.calls[0][0];
      resizeCallback();

      expect(mainContainer.isCompact).toBe(false);
      expect(mainContainer.isIntermediate).toBe(false);
      expect(mainContainer.isWide).toBe(true);
    });
  });

  describe('multiple breakpoint scenarios', () => {
    it.each`
      scenario                | breakpoint | expectedState
      ${'compact on xs'}      | ${'xs'}    | ${{ isCompact: true, isIntermediate: false, isWide: false }}
      ${'compact on sm'}      | ${'sm'}    | ${{ isCompact: true, isIntermediate: false, isWide: false }}
      ${'intermediate on md'} | ${'md'}    | ${{ isCompact: false, isIntermediate: true, isWide: false }}
      ${'intermediate on lg'} | ${'lg'}    | ${{ isCompact: false, isIntermediate: true, isWide: false }}
      ${'wide on xl'}         | ${'xl'}    | ${{ isCompact: false, isIntermediate: false, isWide: true }}
    `('$scenario', ({ breakpoint, expectedState }) => {
      mockGetBreakpointSize.mockReturnValue(breakpoint);

      const mainContainer = useMainContainer();

      expect(mainContainer.isCompact).toBe(expectedState.isCompact);
      expect(mainContainer.isIntermediate).toBe(expectedState.isIntermediate);
      expect(mainContainer.isWide).toBe(expectedState.isWide);
    });
  });
});
