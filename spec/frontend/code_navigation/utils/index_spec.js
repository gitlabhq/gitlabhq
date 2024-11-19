import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  cachedData,
  getCurrentHoverElement,
  setCurrentHoverElement,
  addInteractionClass,
} from '~/code_navigation/utils';

afterEach(() => {
  if (cachedData.has('current')) {
    cachedData.delete('current');
  }
});

describe('getCurrentHoverElement', () => {
  it.each`
    value
    ${'test'}
    ${undefined}
  `('returns cached current key', ({ value }) => {
    if (value) {
      cachedData.set('current', value);
    }

    expect(getCurrentHoverElement()).toEqual(value);
  });
});

describe('setCurrentHoverElement', () => {
  it('sets cached current key', () => {
    setCurrentHoverElement('test');

    expect(getCurrentHoverElement()).toEqual('test');
  });
});

describe('addInteractionClass', () => {
  beforeEach(() => {
    setHTMLFixture(
      '<div data-path="index.js"><div class="blob-content"><div id="LC1" class="line"><span>console</span><span>.</span><span>log</span></div><div id="LC2" class="line"><span>function</span></div></div></div>',
    );
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it.each`
    line | char | index
    ${0} | ${0} | ${0}
    ${0} | ${8} | ${2}
    ${1} | ${0} | ${0}
    ${1} | ${0} | ${0}
  `(
    'sets code navigation attributes for line $line and character $char',
    ({ line, char, index }) => {
      addInteractionClass({ path: 'index.js', d: { start_line: line, start_char: char } });

      expect(document.querySelectorAll(`#LC${line + 1} span`)[index].classList).toContain(
        'js-code-navigation',
      );
    },
  );

  describe('when end_char exists', () => {
    it('wraps part of a word with code navigation element', () => {
      addInteractionClass({
        path: 'index.js',
        d: { start_line: 0, start_char: 0, end_char: 5, end_line: 0 },
      });

      expect(document.querySelectorAll(`#LC1 span`)[0].outerHTML).toEqual(
        '<span><span data-char-index="0" data-line-index="0" class="gl-cursor-pointer code-navigation js-code-navigation">conso</span>le</span>',
      );
    });
  });

  describe('wrapTextNodes', () => {
    beforeEach(() => {
      setHTMLFixture(
        '<div data-path="index.js"><div class="blob-content"><div id="LC1" class="line"> Text </div></div></div>',
      );
    });

    const params = { path: 'index.js', d: { start_line: 0, start_char: 0 } };
    const findAllSpans = () => document.querySelectorAll('#LC1 span');

    it('does not wrap text nodes by default', () => {
      addInteractionClass(params);
      const spans = findAllSpans();
      expect(spans.length).toBe(0);
    });

    it('wraps text nodes if wrapTextNodes is true', () => {
      addInteractionClass({ ...params, wrapTextNodes: true });
      const spans = findAllSpans();

      expect(spans.length).toBe(3);
      expect(spans[0].textContent).toBe(' ');
      expect(spans[1].textContent).toBe('Text');
      expect(spans[2].textContent).toBe(' ');
    });

    it('keeps datasets for all wrapped nodes in a line', () => {
      setHTMLFixture(
        '<div data-path="index.js"><div class="blob-content"><div id="LC1" class="line"><span>console</span><span>.</span><span>log</span></div><div id="LC2" class="line"><span>function</span></div></div></div>',
      );
      addInteractionClass({ ...params, d: { start_line: 0, start_char: 0 }, wrapTextNodes: true });
      // It should set the dataset the first time
      expect(findAllSpans()[0].dataset).toMatchObject({ charIndex: '0', lineIndex: '0' });

      addInteractionClass({ ...params, d: { start_line: 0, start_char: 8 }, wrapTextNodes: true });
      // It should keep the dataset for the first token
      expect(findAllSpans()[0].dataset).toMatchObject({ charIndex: '0', lineIndex: '0' });
      // And set the dataset for the second token
      expect(findAllSpans()[2].dataset).toMatchObject({ charIndex: '8', lineIndex: '0' });
    });

    it('adds the correct class names to wrapped nodes', () => {
      setHTMLFixture(
        '<div data-path="index.js"><div class="blob-content"><div id="LC1" class="line"><span class="test"> Text </span></div></div></div>',
      );
      addInteractionClass({ ...params, wrapTextNodes: true });
      expect(findAllSpans()[1].classList.contains('test')).toBe(true);
    });
  });
});
