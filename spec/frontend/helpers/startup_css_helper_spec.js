import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
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
    beforeEach(() => {
      window.gon = null;
    });

    it('should invoke the action right away', async () => {
      const events = waitForCSSLoaded(mockedCallback);
      await events;

      expect(mockedCallback).toHaveBeenCalledTimes(1);
    });
  });

  describe('with startup css enabled', () => {
    it('should dispatch CSSLoaded when the assets are cached or already loaded', async () => {
      setHTMLFixture(`
        <link href="one.css" data-startupcss="loaded">
        <link href="two.css" data-startupcss="loaded">
      `);
      await waitForCSSLoaded(mockedCallback);

      expect(mockedCallback).toHaveBeenCalledTimes(1);

      resetHTMLFixture();
    });

    it('should wait to call CssLoaded until the assets are loaded', async () => {
      setHTMLFixture(`
        <link href="one.css" data-startupcss="loading">
        <link href="two.css" data-startupcss="loading">
      `);
      const events = waitForCSSLoaded(mockedCallback);
      document.querySelectorAll('[data-startupcss="loading"]').forEach((elem) => {
        // eslint-disable-next-line no-param-reassign
        elem.dataset.startupcss = 'loaded';
      });
      document.dispatchEvent(new CustomEvent('CSSStartupLinkLoaded'));
      await events;

      expect(mockedCallback).toHaveBeenCalledTimes(1);

      resetHTMLFixture();
    });
  });
});
