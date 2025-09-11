import {
  getCssClassDimensions,
  getSystemColorScheme,
  listenSystemColorSchemeChange,
  removeListenerSystemColorSchemeChange,
  getPageBreakpoints,
  resetBreakpointsCache,
} from '~/lib/utils/css_utils';

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

describe('getSystemColorScheme', () => {
  const originalMatchMedia = window.matchMedia;

  beforeEach(() => {
    window.matchMedia = jest.fn().mockImplementation((query) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: jest.fn(), // Deprecated
      removeListener: jest.fn(), // Deprecated
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    }));
  });

  afterAll(() => {
    window.matchMedia = originalMatchMedia;
  });

  it.each`
    colorScheme   | matchesOutput
    ${'gl-dark'}  | ${true}
    ${'gl-light'} | ${false}
  `('returns $colorScheme scheme for gl-system', ({ colorScheme, matchesOutput }) => {
    window.gon.user_color_mode = 'gl-system';
    window.matchMedia.mockReturnValue({ matches: matchesOutput });
    expect(getSystemColorScheme()).toBe(colorScheme);
  });

  it.each(['gl-dark', 'gl-light'])(`returns %s scheme for NON gl-system`, (colorScheme) => {
    window.gon.user_color_mode = colorScheme;
    expect(getSystemColorScheme()).toBe(colorScheme);
  });
});

describe('listenSystemColorSchemeChange', () => {
  let mockMedia;

  beforeEach(() => {
    mockMedia = {
      matches: false,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    };
    window.matchMedia = jest.fn().mockReturnValue(mockMedia);
  });

  it('adds event listener for color scheme changes', () => {
    const callback = jest.fn();
    listenSystemColorSchemeChange(callback);

    expect(window.matchMedia).toHaveBeenCalledWith('(prefers-color-scheme: dark)');
    expect(mockMedia.addEventListener).toHaveBeenCalledWith('change', expect.any(Function));
  });

  it('calls callback with correct color scheme on change', () => {
    const callback = jest.fn();
    listenSystemColorSchemeChange(callback);

    const changeListener = mockMedia.addEventListener.mock.calls[0][1];

    changeListener({ matches: true });
    expect(callback).toHaveBeenCalledWith('gl-dark');

    changeListener({ matches: false });
    expect(callback).toHaveBeenCalledWith('gl-light');
  });

  it('removes event listener when removeListenerSystemColorSchemeChange is called', () => {
    const callback = jest.fn();
    listenSystemColorSchemeChange(callback);
    removeListenerSystemColorSchemeChange(callback);

    expect(mockMedia.removeEventListener).toHaveBeenCalledWith('change', expect.any(Function));
  });
});

describe('getPageBreakpoints', () => {
  let mockMedia;
  let getComputedStyleSpy;

  beforeEach(() => {
    mockMedia = {
      matches: false,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    };
    window.matchMedia = jest.fn().mockReturnValue(mockMedia);

    getComputedStyleSpy = jest.spyOn(window, 'getComputedStyle').mockReturnValue({
      getPropertyValue: jest.fn((prop) => {
        const breakpoints = {
          '--breakpoint-md': '768px',
          '--breakpoint-lg': '992px',
          '--breakpoint-xl': '1200px',
        };
        return breakpoints[prop] || '0px';
      }),
    });
  });

  afterEach(() => {
    getComputedStyleSpy.mockRestore();
    resetBreakpointsCache();
  });

  it('returns breakpoint media queries with short names', () => {
    const breakpoints = getPageBreakpoints();

    expect(breakpoints).toEqual({
      compact: mockMedia,
      intermediate: mockMedia,
      wide: mockMedia,
      narrow: mockMedia,
    });
  });

  it('generates correct media queries for each breakpoint', () => {
    getPageBreakpoints();

    expect(window.matchMedia).toHaveBeenCalledTimes(4);
    expect(window.matchMedia).toHaveBeenNthCalledWith(1, '(max-width: 767px)');
    expect(window.matchMedia).toHaveBeenNthCalledWith(
      2,
      '(min-width: 768px) and (max-width: 1199px)',
    );
    expect(window.matchMedia).toHaveBeenNthCalledWith(3, '(min-width: 1200px)');
    expect(window.matchMedia).toHaveBeenNthCalledWith(4, '(max-width: 991px)');
  });
});
