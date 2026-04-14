import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import {
  withHiddenTooltips,
  observeIntersectionOnce,
  findCoveringElementAtPoint,
  getCoveringElementSync,
  getCoveringElement,
} from '~/lib/utils/viewport';

describe('Viewport utils', () => {
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

  describe('withHiddenTooltips', () => {
    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('hides tooltips during callback execution', () => {
      const tooltip = document.createElement('div');
      tooltip.setAttribute('role', 'tooltip');
      document.body.appendChild(tooltip);

      withHiddenTooltips(() => {
        expect(tooltip.style.display).toBe('none');
      });
    });

    it('restores tooltips after callback completes', () => {
      const tooltip = document.createElement('div');
      tooltip.setAttribute('role', 'tooltip');
      document.body.appendChild(tooltip);

      withHiddenTooltips(() => {});

      expect(tooltip.style.display).toBe('');
    });

    it('restores tooltips even when callback throws', () => {
      const tooltip = document.createElement('div');
      tooltip.setAttribute('role', 'tooltip');
      document.body.appendChild(tooltip);

      expect(() => {
        withHiddenTooltips(() => {
          throw new Error('test');
        });
      }).toThrow('test');

      expect(tooltip.style.display).toBe('');
    });

    it('returns the callback return value', () => {
      const result = withHiddenTooltips(() => 42);

      expect(result).toBe(42);
    });

    it('hides multiple tooltips', () => {
      const tooltips = [1, 2, 3].map(() => {
        const el = document.createElement('div');
        el.setAttribute('role', 'tooltip');
        document.body.appendChild(el);
        return el;
      });

      withHiddenTooltips(() => {
        tooltips.forEach((el) => {
          expect(el.style.display).toBe('none');
        });
      });

      tooltips.forEach((el) => {
        expect(el.style.display).toBe('');
      });
    });

    it('works when no tooltips exist', () => {
      expect(() => {
        withHiddenTooltips(() => {});
      }).not.toThrow();
    });

    it('does not hide or restore already-hidden tooltips (reentrant safety)', () => {
      const tooltip = document.createElement('div');
      tooltip.setAttribute('role', 'tooltip');
      tooltip.style.setProperty('display', 'none', 'important');
      document.body.appendChild(tooltip);

      withHiddenTooltips(() => {});

      expect(tooltip.style.display).toBe('none');
    });
  });

  describe('observeIntersectionOnce', () => {
    it('returns intersection entry', async () => {
      const element = document.createElement('div');
      const mockEntry = { intersectionRect: { top: 100, left: 50 } };

      const promise = observeIntersectionOnce(element);

      triggerIntersection(element, {
        entry: mockEntry,
      });

      const result = await promise;

      expect(result).toMatchObject(mockEntry);
    });
  });

  describe('findCoveringElementAtPoint', () => {
    let element;

    const mockElementFromPoint = (value) => {
      Object.defineProperty(document, 'elementFromPoint', {
        writable: true,
        value: jest.fn(() => value),
      });
    };

    beforeEach(() => {
      element = document.createElement('div');
      document.body.appendChild(element);
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('returns null when no element covers the target', () => {
      mockElementFromPoint(null);
      expect(findCoveringElementAtPoint(element, 50, 100)).toBeNull();
    });

    it('returns null when element at point is the target itself', () => {
      mockElementFromPoint(element);
      expect(findCoveringElementAtPoint(element, 50, 100)).toBeNull();
    });

    it('returns null when element at point is a child of the target', () => {
      const child = document.createElement('span');
      element.appendChild(child);
      mockElementFromPoint(child);
      expect(findCoveringElementAtPoint(element, 50, 100)).toBeNull();
    });

    it('returns sticky element when it covers the target', () => {
      const stickyElement = document.createElement('div');
      document.body.appendChild(stickyElement);
      mockElementFromPoint(stickyElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });

      expect(findCoveringElementAtPoint(element, 50, 100)).toBe(stickyElement);
    });

    it('returns fixed element when it covers the target', () => {
      const fixedElement = document.createElement('div');
      document.body.appendChild(fixedElement);
      mockElementFromPoint(fixedElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'fixed' });

      expect(findCoveringElementAtPoint(element, 50, 100)).toBe(fixedElement);
    });

    it('traverses up to find sticky ancestor', () => {
      const stickyParent = document.createElement('div');
      const coveringChild = document.createElement('div');
      stickyParent.appendChild(coveringChild);
      document.body.appendChild(stickyParent);

      Object.defineProperty(coveringChild, 'offsetParent', { value: stickyParent });

      mockElementFromPoint(coveringChild);
      jest.spyOn(window, 'getComputedStyle').mockImplementation((el) => ({
        position: el === stickyParent ? 'sticky' : 'static',
      }));

      expect(findCoveringElementAtPoint(element, 50, 100)).toBe(stickyParent);
    });

    it('returns null when no sticky or fixed ancestor is found', () => {
      const regularElement = document.createElement('div');
      document.body.appendChild(regularElement);

      Object.defineProperty(regularElement, 'offsetParent', { value: document.body });

      mockElementFromPoint(regularElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'static' });

      expect(findCoveringElementAtPoint(element, 50, 100)).toBeNull();
    });

    it('shifts y coordinate by 1px to avoid border', () => {
      mockElementFromPoint(null);
      findCoveringElementAtPoint(element, 50, 100);
      expect(document.elementFromPoint).toHaveBeenCalledWith(50, 101);
    });
  });

  describe('getCoveringElementSync', () => {
    it('returns synchronously', () => {
      const element = document.createElement('div');
      document.body.appendChild(element);
      jest.spyOn(element, 'getBoundingClientRect').mockReturnValue({ top: 100, left: 50 });
      Object.defineProperty(document, 'elementFromPoint', {
        writable: true,
        value: jest.fn(() => null),
      });

      const result = getCoveringElementSync(element);

      expect(result).toBeNull();
      expect(result).not.toBeInstanceOf(Promise);
      document.body.innerHTML = '';
    });
  });

  describe.each`
    name                        | getCovering
    ${'getCoveringElementSync'} | ${getCoveringElementSync}
    ${'getCoveringElement'}     | ${getCoveringElement}
  `('$name', ({ getCovering }) => {
    let element;

    const triggerWithRect = (top = 100, left = 50) => {
      triggerIntersection(element, {
        entry: { intersectionRect: { top, left } },
      });
    };

    const mockElementFromPoint = (value) => {
      Object.defineProperty(document, 'elementFromPoint', {
        writable: true,
        value: jest.fn(() => value),
      });
    };

    beforeEach(() => {
      element = document.createElement('div');
      document.body.appendChild(element);
      jest.spyOn(element, 'getBoundingClientRect').mockReturnValue({ top: 100, left: 50 });
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('returns null when no element covers the target', async () => {
      mockElementFromPoint(null);

      const promise = getCovering(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });

    it('returns null when element at point is the target itself', async () => {
      mockElementFromPoint(element);

      const promise = getCovering(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });

    it('returns sticky element when it covers the target', async () => {
      const stickyElement = document.createElement('div');
      document.body.appendChild(stickyElement);
      mockElementFromPoint(stickyElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });

      const promise = getCovering(element);
      triggerWithRect();

      expect(await promise).toBe(stickyElement);
    });

    it('returns null when no sticky or fixed ancestor is found', async () => {
      const regularElement = document.createElement('div');
      document.body.appendChild(regularElement);

      Object.defineProperty(regularElement, 'offsetParent', { value: document.body });

      mockElementFromPoint(regularElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'static' });

      const promise = getCovering(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });
  });
});
