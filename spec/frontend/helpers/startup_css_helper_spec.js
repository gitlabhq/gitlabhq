import { waitForCSSLoaded } from '~/helpers/startup_css_helper';

describe('waitForCSSLoaded', () => {
  let mockedCallback;

  beforeEach(() => {
    mockedCallback = jest.fn();
  });

  describe('Promise-like api', () => {
    it('can be used with a callback', async () => {
      await waitForCSSLoaded(mockedCallback);
      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });

    it('can be used as a promise', async () => {
      await waitForCSSLoaded().then(mockedCallback);
      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });
  });

  describe('when gon features is not provided', () => {
    let originalGon;

    beforeEach(() => {
      originalGon = window.gon;
      window.gon = null;
    });

    afterEach(() => {
      window.gon = originalGon;
    });

    it('should invoke the action right away', async () => {
      const events = waitForCSSLoaded(mockedCallback);
      await events;

      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });
  });

  describe('with startup css enabled', () => {
    it('should dispatch CSSLoaded when the assets are cached or already loaded', async () => {
      setFixtures(`
        <link href="one.css" data-startupcss="loaded">
        <link href="two.css" data-startupcss="loaded">
      `);
      await waitForCSSLoaded(mockedCallback);

      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });

    it('should wait to call CssLoaded until the assets are loaded', async () => {
      setFixtures(`
        <link href="one.css" data-startupcss="loading">
        <link href="two.css" data-startupcss="loading">
      `);
      const events = waitForCSSLoaded(mockedCallback);
      document
        .querySelectorAll('[data-startupcss="loading"]')
        .forEach((elem) => elem.setAttribute('data-startupcss', 'loaded'));
      document.dispatchEvent(new CustomEvent('CSSStartupLinkLoaded'));
      await events;

      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });
  });
});
