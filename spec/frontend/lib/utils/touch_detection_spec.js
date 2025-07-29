import { hasTouchCapability } from '~/lib/utils/touch_detection';

describe('Touch Detection Utility', () => {
  let originalOntouchstart;
  let originalMaxTouchPoints;
  let originalMsMaxTouchPoints;
  let originalDocumentTouch;

  beforeEach(() => {
    originalOntouchstart = window.ontouchstart;
    originalMaxTouchPoints = Object.getOwnPropertyDescriptor(navigator, 'maxTouchPoints');
    originalMsMaxTouchPoints = Object.getOwnPropertyDescriptor(navigator, 'msMaxTouchPoints');
    originalDocumentTouch = window.DocumentTouch;

    delete window.ontouchstart;
    delete window.DocumentTouch;
  });

  afterEach(() => {
    if (originalOntouchstart !== undefined) {
      window.ontouchstart = originalOntouchstart;
    } else {
      delete window.ontouchstart;
    }

    if (originalMaxTouchPoints) {
      Object.defineProperty(navigator, 'maxTouchPoints', originalMaxTouchPoints);
    } else {
      delete navigator.maxTouchPoints;
    }

    if (originalMsMaxTouchPoints) {
      Object.defineProperty(navigator, 'msMaxTouchPoints', originalMsMaxTouchPoints);
    } else {
      delete navigator.msMaxTouchPoints;
    }

    if (originalDocumentTouch) {
      window.DocumentTouch = originalDocumentTouch;
    }
  });

  describe('hasTouchCapability', () => {
    it('returns true when ontouchstart is available', () => {
      window.ontouchstart = null;

      expect(hasTouchCapability()).toBe(true);
    });

    it('returns true when maxTouchPoints is greater than 0', () => {
      Object.defineProperty(navigator, 'maxTouchPoints', {
        value: 1,
        configurable: true,
      });

      expect(hasTouchCapability()).toBe(true);
    });

    it('returns true when msMaxTouchPoints is greater than 0', () => {
      Object.defineProperty(navigator, 'maxTouchPoints', {
        value: 0,
        configurable: true,
      });
      Object.defineProperty(navigator, 'msMaxTouchPoints', {
        value: 1,
        configurable: true,
      });

      expect(hasTouchCapability()).toBe(true);
    });

    it('returns false when no touch capability detected', () => {
      Object.defineProperty(navigator, 'maxTouchPoints', {
        value: 0,
        configurable: true,
      });
      Object.defineProperty(navigator, 'msMaxTouchPoints', {
        value: 0,
        configurable: true,
      });

      expect(hasTouchCapability()).toBe(false);
    });

    it('returns true when DocumentTouch is available and document is instance of DocumentTouch', () => {
      Object.defineProperty(navigator, 'maxTouchPoints', {
        value: 0,
        configurable: true,
      });
      Object.defineProperty(navigator, 'msMaxTouchPoints', {
        value: 0,
        configurable: true,
      });

      window.DocumentTouch = function DocumentTouch() {};
      Object.setPrototypeOf(document, window.DocumentTouch.prototype);

      expect(hasTouchCapability()).toBe(true);
    });
  });
});
