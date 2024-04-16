import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  addClassIfElementExists,
  canScrollUp,
  canScrollDown,
  getContentWrapperHeight,
  parseBooleanDataAttributes,
  isElementVisible,
  getParents,
  getParentByTagName,
  setAttributes,
  replaceCommentsWith,
  waitForElement,
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
      setHTMLFixture(fixture);
      parentElement = document.querySelector('.parent');
    });

    afterEach(() => {
      resetHTMLFixture();
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
      setHTMLFixture('<div data-foo-bar data-baz data-qux="">');
      element = document.querySelector('[data-foo-bar]');
    });

    afterEach(() => {
      resetHTMLFixture();
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
  `('isElementVisible', ({ offsetWidth, offsetHeight, clientRectsLength, visible }) => {
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
  });

  describe('getParents', () => {
    it('gets all parents of an element', () => {
      const el = document.createElement('div');
      el.innerHTML = '<p><span><strong><mark>hello world';

      expect(getParents(el.querySelector('mark'))).toEqual([
        el.querySelector('strong'),
        el.querySelector('span'),
        el.querySelector('p'),
        el,
      ]);
    });
  });

  describe('getParentByTagName', () => {
    const el = document.createElement('div');
    el.innerHTML = '<p><span><strong><mark>hello world';

    it.each`
      tagName     | parent
      ${'strong'} | ${el.querySelector('strong')}
      ${'span'}   | ${el.querySelector('span')}
      ${'p'}      | ${el.querySelector('p')}
      ${'pre'}    | ${undefined}
    `('gets a parent by tag name', ({ tagName, parent }) => {
      expect(getParentByTagName(el.querySelector('mark'), tagName)).toBe(parent);
    });
  });

  describe('setAttributes', () => {
    it('sets multiple attribues on element', () => {
      const div = document.createElement('div');

      setAttributes(div, { class: 'test', title: 'another test' });

      expect(div.getAttribute('class')).toBe('test');
      expect(div.getAttribute('title')).toBe('another test');
    });
  });

  describe('getContentWrapperHeight', () => {
    const fixture = `
      <div>
        <div class="content-wrapper">
          <div class="content"></div>
        </div>
      </div>
    `;

    beforeEach(() => {
      setHTMLFixture(fixture);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('returns the height of default element that exists', () => {
      expect(getContentWrapperHeight()).toBe('0px');
    });

    it('returns the height of an element that exists', () => {
      expect(getContentWrapperHeight('.content')).toBe('0px');
    });

    it('returns an empty string for a class that does not exist', () => {
      expect(getContentWrapperHeight('.does-not-exist')).toBe('');
    });
  });

  describe('replaceCommentsWith', () => {
    let div;
    beforeEach(() => {
      div = document.createElement('div');
    });

    it('replaces the comments in a DOM node with an element', () => {
      div.innerHTML = '<h1> hi there <!-- some comment --> <p> <!-- another comment -->';

      replaceCommentsWith(div, 'comment');

      expect(div.innerHTML).toBe(
        '<h1> hi there <comment> some comment </comment> <p> <comment> another comment </comment></p></h1>',
      );
    });
  });

  describe('waitForElement', () => {
    const fixture = '<div class="wrapper"></div>';
    const mockElementSelector = 'some-selector';
    const mockElement = document.createElement('div');
    mockElement.classList.add(mockElementSelector);

    beforeEach(() => setHTMLFixture(fixture));

    afterEach(() => resetHTMLFixture());

    it('resolves immediately if element is already in the DOM', async () => {
      document.querySelector('.wrapper').appendChild(mockElement);
      const result = await waitForElement(`.${mockElementSelector}`);

      expect(result).toBe(mockElement);
    });

    it('resolves after element is added to the DOM', async () => {
      const waitForElementPromise = waitForElement(`.${mockElementSelector}`);
      document.querySelector('.wrapper').appendChild(mockElement);
      const result = await waitForElementPromise;

      expect(result).toBe(mockElement);
    });

    describe('if no element found', () => {
      const mockDisconnect = jest.fn();
      let OriginalMutationObserver;
      const timeoutDelay = 100;
      class MutationObserverMock {
        constructor() {
          this.observe = jest.fn();
          this.disconnect = mockDisconnect;
        }
      }

      beforeEach(() => {
        OriginalMutationObserver = global.MutationObserver;
        global.MutationObserver = MutationObserverMock;
      });

      afterEach(() => {
        global.MutationObserver = OriginalMutationObserver;
      });

      it('disconnects the observer and rejects the promise after the timeout delay', async () => {
        const waitForElementPromise = waitForElement('.some-unavailable-element', timeoutDelay);
        jest.advanceTimersByTime(timeoutDelay);

        expect(mockDisconnect).toHaveBeenCalled();
        await expect(waitForElementPromise).rejects.toMatch('Timeout: Element not found');
      });
    });
  });
});
