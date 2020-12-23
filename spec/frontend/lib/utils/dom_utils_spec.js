import {
  addClassIfElementExists,
  canScrollUp,
  canScrollDown,
  parseBooleanDataAttributes,
  isElementVisible,
  isElementHidden,
} from '~/lib/utils/dom_utils';

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
    [1, 100].forEach((scrollTop) => {
      it(`is true if scrollTop is > 0 (${scrollTop})`, () => {
        expect(
          canScrollUp({
            scrollTop,
          }),
        ).toBe(true);
      });
    });

    [0, -10].forEach((scrollTop) => {
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

  describe('parseBooleanDataAttributes', () => {
    let element;

    beforeEach(() => {
      setFixtures('<div data-foo-bar data-baz data-qux="">');
      element = document.querySelector('[data-foo-bar]');
    });

    it('throws if not given an element', () => {
      expect(() => parseBooleanDataAttributes(null, ['baz'])).toThrow();
    });

    it('throws if not given an array of dataset names', () => {
      expect(() => parseBooleanDataAttributes(element)).toThrow();
    });

    it('returns an empty object if given an empty array of names', () => {
      expect(parseBooleanDataAttributes(element, [])).toEqual({});
    });

    it('correctly parses boolean-like data attributes', () => {
      expect(
        parseBooleanDataAttributes(element, [
          'fooBar',
          'foobar',
          'baz',
          'qux',
          'doesNotExist',
          'toString',
        ]),
      ).toEqual({
        fooBar: true,
        foobar: false,
        baz: true,
        qux: true,
        doesNotExist: false,

        // Ensure prototype properties aren't false positives
        toString: false,
      });
    });
  });

  describe.each`
    offsetWidth | offsetHeight | clientRectsLength | visible
    ${0}        | ${0}         | ${0}              | ${false}
    ${1}        | ${0}         | ${0}              | ${true}
    ${0}        | ${1}         | ${0}              | ${true}
    ${0}        | ${0}         | ${1}              | ${true}
  `(
    'isElementVisible and isElementHidden',
    ({ offsetWidth, offsetHeight, clientRectsLength, visible }) => {
      const element = {
        offsetWidth,
        offsetHeight,
        getClientRects: () => new Array(clientRectsLength),
      };

      const paramDescription = `offsetWidth=${offsetWidth}, offsetHeight=${offsetHeight}, and getClientRects().length=${clientRectsLength}`;

      describe('isElementVisible', () => {
        it(`returns ${visible} when ${paramDescription}`, () => {
          expect(isElementVisible(element)).toBe(visible);
        });
      });

      describe('isElementHidden', () => {
        it(`returns ${!visible} when ${paramDescription}`, () => {
          expect(isElementHidden(element)).toBe(!visible);
        });
      });
    },
  );
});
