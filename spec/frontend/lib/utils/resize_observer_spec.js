import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { contentTop } from '~/lib/utils/common_utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';

jest.mock('~/lib/utils/common_utils');

function mockStickyHeaderSize(val) {
  contentTop.mockReturnValue(val);
}

describe('ResizeObserver Utility', () => {
  let cleanup;
  const triggerResize = () => {
    const entry = document.querySelector('#content-body');
    entry.dispatchEvent(new CustomEvent(`ResizeUpdate`, { detail: { entry } }));
  };

  beforeEach(() => {
    mockStickyHeaderSize(90);

    jest.spyOn(document.documentElement, 'scrollTo');

    setHTMLFixture(
      `<div id="content-body"><div id="note_1234">note to scroll to</div><textarea id="reply-field"></textarea></div>`,
    );

    const target = document.querySelector('#note_1234');

    jest.spyOn(target, 'getBoundingClientRect').mockReturnValue({ top: 200 });
  });

  afterEach(() => {
    contentTop.mockReset();
    resetHTMLFixture();
  });

  describe('Observer behavior', () => {
    it('returns null for empty target', () => {
      cleanup = scrollToTargetOnResize({
        targetId: '',
        container: '#content-body',
      });

      expect(cleanup).toBe(null);
    });

    it('does not scroll if target does not exist', () => {
      scrollToTargetOnResize({
        targetId: 'some_imaginary_id',
        container: '#content-body',
      });

      triggerResize();

      expect(document.documentElement.scrollTo).not.toHaveBeenCalled();
    });

    describe('with existing target', () => {
      const cleanupTimeoutMs = 100;
      const topHeight = 110;
      const scrollAmount = 160;

      beforeEach(() => {
        cleanup = scrollToTargetOnResize({
          targetId: 'note_1234',
          container: '#content-body',
        });
      });

      it('returns cleanup function', () => {
        cleanup();

        jest.advanceTimersByTime(cleanupTimeoutMs);

        triggerResize();

        expect(document.documentElement.scrollTo).not.toHaveBeenCalled();
      });

      it('scrolls body so anchor is just below sticky header (contentTop)', () => {
        triggerResize();

        expect(document.documentElement.scrollTo).toHaveBeenCalledWith({
          behavior: 'instant',
          top: topHeight,
        });
      });

      it('maintains scroll position relative to anchor after user scroll', () => {
        // Initial scroll to anchor
        triggerResize();

        // Simulate user scrolling down
        window.scrollY = scrollAmount;
        window.dispatchEvent(new Event('scroll'));

        // Trigger resize again
        triggerResize();

        // Should maintain the 50px offset from original position
        expect(document.documentElement.scrollTo).toHaveBeenCalledWith({
          top: topHeight + scrollAmount,
          behavior: 'instant',
        });
      });

      it('does not scroll if another element is focused', () => {
        const anchorEl = document.getElementById('reply-field');
        anchorEl.focus();

        triggerResize();

        expect(document.documentElement.scrollTo).not.toHaveBeenCalled();
      });
    });
  });
});
