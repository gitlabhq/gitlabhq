import { createTestingPinia } from '@pinia/testing';
import { useViewport } from '~/pinia/global_stores/viewport';
import { isNarrowScreenMediaQuery } from '~/lib/utils/css_utils';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/css_utils');

describe('Viewport store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  describe('isNarrowScreen', () => {
    let handler;

    const setNarrowScreen = (isNarrow) => {
      isNarrowScreenMediaQuery.mockReturnValue({
        matches: isNarrow,
        addEventListener: jest.fn((_, fn) => {
          handler = fn;
        }),
      });
    };
    const triggerChange = (isNarrow) => {
      handler({ matches: isNarrow });
    };

    beforeEach(() => {
      isNarrowScreenMediaQuery.mockReset();
    });

    it('returns true if screen is narrow', () => {
      setNarrowScreen(true);
      expect(useViewport().isNarrowScreen).toBe(true);
    });

    it('returns false if screen is not narrow', () => {
      setNarrowScreen(false);
      expect(useViewport().isNarrowScreen).toBe(false);
    });

    it('updates value if screen changes', async () => {
      setNarrowScreen(true);
      useViewport();
      triggerChange(false);
      await waitForPromises();
      expect(useViewport().isNarrowScreen).toBe(false);
    });
  });
});
