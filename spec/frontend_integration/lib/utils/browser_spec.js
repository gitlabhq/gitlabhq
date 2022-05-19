import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import * as commonUtils from '~/lib/utils/common_utils';

describe('common_utils browser specific specs', () => {
  const mockOffsetHeight = (elem, offsetHeight) => {
    Object.defineProperty(elem, 'offsetHeight', { value: offsetHeight });
  };

  const mockBoundingClientRect = (elem, rect) => {
    jest.spyOn(elem, 'getBoundingClientRect').mockReturnValue(rect);
  };

  describe('contentTop', () => {
    it('does not add height for fileTitle or compareVersionsHeader if screen is too small', () => {
      jest.spyOn(breakpointInstance, 'isDesktop').mockReturnValue(false);

      setHTMLFixture(`
          <div class="diff-file file-title-flex-parent">
            blah blah blah
          </div>
          <div class="mr-version-controls">
            more blah blah blah
          </div>
        `);

      expect(commonUtils.contentTop()).toBe(0);

      resetHTMLFixture();
    });

    it('adds height for fileTitle and compareVersionsHeader screen is large enough', () => {
      jest.spyOn(breakpointInstance, 'isDesktop').mockReturnValue(true);

      setHTMLFixture(`
          <div class="diff-file file-title-flex-parent">
            blah blah blah
          </div>
          <div class="mr-version-controls">
            more blah blah blah
          </div>
        `);

      mockOffsetHeight(document.querySelector('.diff-file'), 100);
      mockOffsetHeight(document.querySelector('.mr-version-controls'), 18);
      expect(commonUtils.contentTop()).toBe(18);

      resetHTMLFixture();
    });
  });

  describe('isInViewport', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    afterEach(() => {
      document.body.removeChild(el);
    });

    it('returns true when provided `el` is in viewport', () => {
      el.setAttribute('style', `position: absolute; right: ${window.innerWidth + 0.2};`);
      mockBoundingClientRect(el, {
        x: 8,
        y: 8,
        width: 0,
        height: 0,
        top: 8,
        right: 8,
        bottom: 8,
        left: 8,
      });

      document.body.appendChild(el);

      expect(commonUtils.isInViewport(el)).toBe(true);
    });

    it('returns false when provided `el` is not in viewport', () => {
      el.setAttribute('style', 'position: absolute; top: -1000px; left: -1000px;');
      mockBoundingClientRect(el, {
        x: -1000,
        y: -1000,
        width: 0,
        height: 0,
        top: -1000,
        right: -1000,
        bottom: -1000,
        left: -1000,
      });

      document.body.appendChild(el);

      expect(commonUtils.isInViewport(el)).toBe(false);
    });
  });
});
