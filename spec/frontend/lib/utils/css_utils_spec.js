import { getCssClassDimensions } from '~/lib/utils/css_utils';

describe('getCssClassDimensions', () => {
  const mockDimensions = { width: 1, height: 2 };
  let actual;

  beforeEach(() => {
    jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue(mockDimensions);
    actual = getCssClassDimensions('foo bar');
  });

  it('returns the measured width and height', () => {
    expect(actual).toEqual(mockDimensions);
  });

  it('measures an element with the given classes', () => {
    expect(Element.prototype.getBoundingClientRect).toHaveBeenCalledTimes(1);

    const [tempElement] = Element.prototype.getBoundingClientRect.mock.contexts;
    expect([...tempElement.classList]).toEqual(['foo', 'bar']);
  });
});
