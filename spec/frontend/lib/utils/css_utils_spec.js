import {
  getCssClassDimensions,
  getSystemColorScheme,
  listenSystemColorSchemeChange,
  removeListenerSystemColorSchemeChange,
  isNarrowScreenAddListener,
  isNarrowScreenRemoveListener,
  isNarrowScreen,
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

describe('listenNarrowScreen', () => {
  let mockMedia;

  beforeEach(() => {
    mockMedia = {
      matches: false,
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    };
    window.matchMedia = jest.fn().mockReturnValue(mockMedia);
    window.getComputedStyle = jest.fn().mockReturnValue({
      getPropertyValue: jest.fn().mockReturnValue('1200px'),
    });
  });

  it('checks for screen size', () => {
    mockMedia.matches = true;
    expect(isNarrowScreen()).toBe(true);
    mockMedia.matches = false;
    expect(isNarrowScreen()).toBe(false);
  });

  it('adds event listener for screen size changes', () => {
    const callback = jest.fn();
    isNarrowScreenAddListener(callback);
    expect(window.matchMedia).toHaveBeenCalledWith('(max-width: 1199px)');
    expect(mockMedia.addEventListener).toHaveBeenCalledWith('change', expect.any(Function));
  });

  it('removes event listener for screen size changes', () => {
    const callback = jest.fn();
    isNarrowScreenAddListener(callback);
    isNarrowScreenRemoveListener(callback);
    expect(mockMedia.removeEventListener).toHaveBeenCalledWith('change', expect.any(Function));
  });
});
