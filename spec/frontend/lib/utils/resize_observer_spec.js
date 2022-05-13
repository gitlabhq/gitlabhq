import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { contentTop } from '~/lib/utils/common_utils';
import { scrollToTargetOnResize } from '~/lib/utils/resize_observer';

jest.mock('~/lib/utils/common_utils');

function mockStickyHeaderSize(val) {
  contentTop.mockReturnValue(val);
}

describe('ResizeObserver Utility', () => {
  let observer;
  const triggerResize = () => {
    const entry = document.querySelector('#content-body');
    entry.dispatchEvent(new CustomEvent(`ResizeUpdate`, { detail: { entry } }));
  };

  beforeEach(() => {
    mockStickyHeaderSize(90);

    jest.spyOn(document.documentElement, 'scrollTo');

    setHTMLFixture(`<div id="content-body"><div id="note_1234">note to scroll to</div></div>`);

    const target = document.querySelector('#note_1234');

    jest.spyOn(target, 'getBoundingClientRect').mockReturnValue({ top: 200 });
  });

  afterEach(() => {
    contentTop.mockReset();
    resetHTMLFixture();
  });

  describe('Observer behavior', () => {
    it('returns null for empty target', () => {
      observer = scrollToTargetOnResize({
        targetId: '',
        container: '#content-body',
      });

      expect(observer).toBe(null);
    });

    it('does not scroll if target does not exist', () => {
      observer = scrollToTargetOnResize({
        targetId: 'some_imaginary_id',
        container: '#content-body',
      });

      triggerResize();

      expect(document.documentElement.scrollTo).not.toHaveBeenCalled();
    });

    const interactionEvents = ['mousedown', 'touchstart', 'keydown', 'wheel'];
    it.each(interactionEvents)('does not hijack scroll after user input from %s', (eventType) => {
      const event = new Event(eventType);
      document.dispatchEvent(event);

      triggerResize();

      expect(document.documentElement.scrollTo).not.toHaveBeenCalledWith();
    });

    describe('with existing target', () => {
      beforeEach(() => {
        observer = scrollToTargetOnResize({
          targetId: 'note_1234',
          container: '#content-body',
        });
      });

      it('returns ResizeObserver instance', () => {
        expect(observer).toBeInstanceOf(ResizeObserver);
      });

      it('scrolls body so anchor is just below sticky header (contentTop)', () => {
        triggerResize();

        expect(document.documentElement.scrollTo).toHaveBeenCalledWith({ top: 110 });
      });
    });
  });
});
