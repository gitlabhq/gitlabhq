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
  `('it returns cached current key', ({ value }) => {
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
    setFixtures(
      '<div id="LC1"><span>console</span><span>.</span><span>log</span></div><div id="LC2"><span>function</span></div>',
    );
  });

  it.each`
    line | char | index
    ${0} | ${0} | ${0}
    ${0} | ${8} | ${2}
    ${1} | ${0} | ${0}
  `(
    'it sets code navigation attributes for line $line and character $char',
    ({ line, char, index }) => {
      addInteractionClass({ start_line: line, start_char: char });

      expect(document.querySelectorAll(`#LC${line + 1} span`)[index].classList).toContain(
        'js-code-navigation',
      );
    },
  );
});
