import { addClassIfElementExists, canScrollUp, canScrollDown } from '~/lib/utils/dom_utils';

const TEST_MARGIN = 5;

describe('DOM Utils', () => {
  describe('addClassIfElementExists', () => {
    const className = 'biology';
    const fixture = `
      <div class="parent">
        <div class="child"></div>
      </div>
    `;

    let parentElement;

    beforeEach(() => {
      setFixtures(fixture);
      parentElement = document.querySelector('.parent');
    });

    it('adds class if element exists', () => {
      const childElement = parentElement.querySelector('.child');

      expect(childElement).not.toBe(null);

      addClassIfElementExists(childElement, className);

      expect(childElement.classList).toContainEqual(className);
    });

    it('does not throw if element does not exist', () => {
      const childElement = parentElement.querySelector('.other-child');

      expect(childElement).toBe(null);

      addClassIfElementExists(childElement, className);
    });
  });

  describe('canScrollUp', () => {
    [1, 100].forEach(scrollTop => {
      it(`is true if scrollTop is > 0 (${scrollTop})`, () => {
        expect(
          canScrollUp({
            scrollTop,
          }),
        ).toBe(true);
      });
    });

    [0, -10].forEach(scrollTop => {
      it(`is false if scrollTop is <= 0 (${scrollTop})`, () => {
        expect(
          canScrollUp({
            scrollTop,
          }),
        ).toBe(false);
      });
    });

    it('is true if scrollTop is > margin', () => {
      expect(
        canScrollUp(
          {
            scrollTop: TEST_MARGIN + 1,
          },
          TEST_MARGIN,
        ),
      ).toBe(true);
    });

    it('is false if scrollTop is <= margin', () => {
      expect(
        canScrollUp(
          {
            scrollTop: TEST_MARGIN,
          },
          TEST_MARGIN,
        ),
      ).toBe(false);
    });
  });

  describe('canScrollDown', () => {
    let element;

    beforeEach(() => {
      element = {
        scrollTop: 7,
        offsetHeight: 22,
        scrollHeight: 30,
      };
    });

    it('is true if element can be scrolled down', () => {
      expect(canScrollDown(element)).toBe(true);
    });

    it('is false if element cannot be scrolled down', () => {
      element.scrollHeight -= 1;

      expect(canScrollDown(element)).toBe(false);
    });

    it('is true if element can be scrolled down, with margin given', () => {
      element.scrollHeight += TEST_MARGIN;

      expect(canScrollDown(element, TEST_MARGIN)).toBe(true);
    });

    it('is false if element cannot be scrolled down, with margin given', () => {
      expect(canScrollDown(element, TEST_MARGIN)).toBe(false);
    });
  });
});
