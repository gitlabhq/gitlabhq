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

    setFixtures(`<div id="content-body"><div class="target">element to scroll to</div></div>`);

    const target = document.querySelector('.target');

    jest.spyOn(target, 'getBoundingClientRect').mockReturnValue({ top: 200 });

    observer = scrollToTargetOnResize({
      target: '.target',
      container: '#content-body',
    });
  });

  afterEach(() => {
    contentTop.mockReset();
  });

  describe('Observer behavior', () => {
    it('returns null for empty target', () => {
      observer = scrollToTargetOnResize({
        target: '',
        container: '#content-body',
      });

      expect(observer).toBe(null);
    });

    it('returns ResizeObserver instance', () => {
      expect(observer).toBeInstanceOf(ResizeObserver);
    });

    it('scrolls body so anchor is just below sticky header (contentTop)', () => {
      triggerResize();

      expect(document.documentElement.scrollTo).toHaveBeenCalledWith({ top: 110 });
    });

    const interactionEvents = ['mousedown', 'touchstart', 'keydown', 'wheel'];
    it.each(interactionEvents)('does not hijack scroll after user input from %s', (eventType) => {
      const event = new Event(eventType);
      document.dispatchEvent(event);

      triggerResize();

      expect(document.documentElement.scrollTo).not.toHaveBeenCalledWith();
    });
  });
});
