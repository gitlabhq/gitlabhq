import { setHTMLFixture } from 'helpers/fixtures';
import { loadStartupCSS } from '~/behaviors/load_startup_css';

describe('behaviors/load_startup_css', () => {
  let loadListener;

  const setupListeners = () => {
    document
      .querySelectorAll('link')
      .forEach(x => x.addEventListener('load', () => loadListener(x)));
  };

  beforeEach(() => {
    loadListener = jest.fn();

    setHTMLFixture(`
      <meta charset="utf-8" />
      <link media="print" src="./lorem-print.css" />
      <link media="print" src="./ipsum-print.css" />
      <link media="all" src="./dolar-all.css" />
    `);

    setupListeners();

    loadStartupCSS();
  });

  it('does nothing at first', () => {
    expect(loadListener).not.toHaveBeenCalled();
  });

  describe('on window load', () => {
    beforeEach(() => {
      window.dispatchEvent(new Event('load'));
    });

    it('dispatches load to the print links', () => {
      expect(loadListener.mock.calls.map(([el]) => el.getAttribute('src'))).toEqual([
        './lorem-print.css',
        './ipsum-print.css',
      ]);
    });
  });
});
