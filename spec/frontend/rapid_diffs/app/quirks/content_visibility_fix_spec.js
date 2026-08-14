import { disableBrokenContentVisibility } from '~/rapid_diffs/app/quirks/content_visibility_fix';

describe('disableBrokenContentVisibility', () => {
  const originalUserAgent = navigator.userAgent;
  let root;

  const setUserAgent = (value) => {
    Object.defineProperty(navigator, 'userAgent', { value, configurable: true });
  };

  const getOverride = () => root.style.getPropertyValue('--rd-content-visibility-auto');

  beforeEach(() => {
    root = document.createElement('div');
  });

  afterEach(() => {
    setUserAgent(originalUserAgent);
  });

  describe.each`
    browser              | userAgent
    ${'Safari 18.5'}     | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15'}
    ${'Safari 26.5'}     | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Safari/605.1.15'}
    ${'Safari 27.0'}     | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0 Safari/605.1.15'}
    ${'iOS Safari 26.5'} | ${'Mozilla/5.0 (iPhone; CPU iPhone OS 26_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.5 Mobile/15E148 Safari/604.1'}
  `('on $browser', ({ userAgent }) => {
    it('disables content-visibility', () => {
      setUserAgent(userAgent);

      disableBrokenContentVisibility(root);

      expect(getOverride()).toBe('visible');
    });
  });

  describe('on Chrome 137', () => {
    it('disables content-visibility', () => {
      setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36',
      );

      disableBrokenContentVisibility(root);

      expect(getOverride()).toBe('visible');
    });
  });

  describe.each`
    browser          | userAgent
    ${'Chrome 138'}  | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36'}
    ${'Chrome 151'}  | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36'}
    ${'Firefox 145'} | ${'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:145.0) Gecko/20100101 Firefox/145.0'}
  `('on $browser', ({ userAgent }) => {
    it('keeps content-visibility enabled', () => {
      setUserAgent(userAgent);

      disableBrokenContentVisibility(root);

      expect(getOverride()).toBe('');
    });
  });
});
