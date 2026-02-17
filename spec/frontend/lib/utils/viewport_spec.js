import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { observeIntersectionOnce, getCoveringElement } from '~/lib/utils/viewport';

describe('Viewport utils', () => {
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

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

  describe('getCoveringElement', () => {
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
    });

    afterEach(() => {
      document.body.innerHTML = '';
    });

    it('returns null when no element covers the target', async () => {
      mockElementFromPoint(null);

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });

    it('returns null when element at point is the target itself', async () => {
      mockElementFromPoint(element);

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });

    it('returns null when element at point is a child of the target', async () => {
      const child = document.createElement('span');
      element.appendChild(child);
      mockElementFromPoint(child);

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBeNull();
    });

    it('returns sticky element when it covers the target', async () => {
      const stickyElement = document.createElement('div');
      document.body.appendChild(stickyElement);
      mockElementFromPoint(stickyElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'sticky' });

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBe(stickyElement);
    });

    it('returns fixed element when it covers the target', async () => {
      const fixedElement = document.createElement('div');
      document.body.appendChild(fixedElement);
      mockElementFromPoint(fixedElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'fixed' });

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBe(fixedElement);
    });

    it('traverses up to find sticky ancestor', async () => {
      const stickyParent = document.createElement('div');
      const coveringChild = document.createElement('div');
      stickyParent.appendChild(coveringChild);
      document.body.appendChild(stickyParent);

      Object.defineProperty(coveringChild, 'offsetParent', { value: stickyParent });

      mockElementFromPoint(coveringChild);
      jest.spyOn(window, 'getComputedStyle').mockImplementation((el) => ({
        position: el === stickyParent ? 'sticky' : 'static',
      }));

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBe(stickyParent);
    });

    it('returns null when no sticky or fixed ancestor is found', async () => {
      const regularElement = document.createElement('div');
      document.body.appendChild(regularElement);

      Object.defineProperty(regularElement, 'offsetParent', { value: document.body });

      mockElementFromPoint(regularElement);
      jest.spyOn(window, 'getComputedStyle').mockReturnValue({ position: 'static' });

      const promise = getCoveringElement(element);
      triggerWithRect();

      expect(await promise).toBe(null);
    });
  });
});
