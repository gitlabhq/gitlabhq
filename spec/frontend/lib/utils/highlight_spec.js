import highlight from '~/lib/utils/highlight';

describe('highlight', () => {
  it(`should appropriately surround substring matches`, () => {
    const expected = 'g<b>i</b><b>t</b>lab';

    expect(highlight('gitlab', 'it')).toBe(expected);
  });

  it(`should return an empty string in the case of invalid inputs`, () => {
    [null, undefined].forEach((input) => {
      expect(highlight(input, 'match')).toBe('');
    });
  });

  it(`should return the original value if match is null, undefined, or ''`, () => {
    [null, undefined].forEach((match) => {
      expect(highlight('gitlab', match)).toBe('gitlab');
    });
  });

  it(`should highlight matches in non-string inputs`, () => {
    const expected = '123<b>4</b><b>5</b>6';

    expect(highlight(123456, 45)).toBe(expected);
  });

  it(`should sanitize the input string before highlighting matches`, () => {
    const expected = 'hello <b>w</b>orld';

    expect(highlight('hello <b>world</b>', 'w')).toBe(expected);
  });

  it(`should not highlight anything if no matches are found`, () => {
    expect(highlight('gitlab', 'hello')).toBe('gitlab');
  });

  it(`should allow wrapping elements to be customized`, () => {
    const expected = '1<hello>2</hello>3';

    expect(highlight('123', '2', '<hello>', '</hello>')).toBe(expected);
  });

  it(`should prevent xss with no match`, () => {
    const expected = '';

    expect(highlight('<script>alert(document.domain)</script>', '')).toBe(expected);
  });

  it(`should prevent xss with match`, () => {
    const expected = 'test';

    expect(highlight('test<script>alert(document.domain)</script>', 'alert')).toBe(expected);
  });
});
