import {
  handleLoadedEvents,
  waitForCSSLoaded,
} from '../../../app/assets/javascripts/helpers/startup_css_helper';

describe('handleLoadedEvents', () => {
  let mock;
  beforeEach(() => {
    mock = jest.fn();
  });

  it('should not call the callback on wrong conditions', () => {
    const resolverToCall = handleLoadedEvents(mock);
    resolverToCall({ type: 'UnrelatedEvent' });
    resolverToCall({ type: 'UnrelatedEvent' });
    resolverToCall({ type: 'UnrelatedEvent' });
    resolverToCall({ type: 'UnrelatedEvent' });
    resolverToCall({ type: 'CSSLoaded' });
    resolverToCall();
    expect(mock).not.toHaveBeenCalled();
  });

  it('should call the callback when all the events have been triggered', () => {
    const resolverToCall = handleLoadedEvents(mock);
    resolverToCall();
    resolverToCall({ type: 'DOMContentLoaded' });
    resolverToCall({ type: 'CSSLoaded' });
    resolverToCall();
    expect(mock).toHaveBeenCalledTimes(1);
  });
});

describe('waitForCSSLoaded', () => {
  let mock;
  beforeEach(() => {
    mock = jest.fn();
  });

  describe('with startup css disabled', () => {
    beforeEach(() => {
      gon.features = {
        startupCss: false,
      };
    });

    it('should call CssLoaded when the conditions are met', async () => {
      const docAddListener = jest.spyOn(document, 'addEventListener');
      const docRemoveListener = jest.spyOn(document, 'removeEventListener');
      const docDispatch = jest.spyOn(document, 'dispatchEvent');
      const events = waitForCSSLoaded(mock);

      expect(docAddListener).toHaveBeenCalledTimes(3);
      expect(docDispatch.mock.calls[0][0].type).toBe('CSSStartupLinkLoaded');

      document.dispatchEvent(new CustomEvent('DOMContentLoaded'));
      await events;

      expect(docDispatch).toHaveBeenCalledTimes(3);
      expect(docDispatch.mock.calls[2][0].type).toBe('CSSLoaded');
      expect(docRemoveListener).toHaveBeenCalledTimes(1);
      expect(mock).toHaveBeenCalledTimes(1);
    });
  });

  describe('with startup css enabled', () => {
    let docAddListener;
    let docRemoveListener;
    let docDispatch;

    beforeEach(() => {
      docAddListener = jest.spyOn(document, 'addEventListener');
      docRemoveListener = jest.spyOn(document, 'removeEventListener');
      docDispatch = jest.spyOn(document, 'dispatchEvent');
      gon.features = {
        startupCss: true,
      };
    });

    it('should call CssLoaded if the assets are cached', async () => {
      const events = waitForCSSLoaded(mock);
      const fixtures = `
        <link href="one.css" data-startupcss="loaded">
        <link href="two.css" data-startupcss="loaded">
      `;
      setFixtures(fixtures);

      expect(docAddListener).toHaveBeenCalledTimes(3);
      expect(docDispatch.mock.calls[0][0].type).toBe('CSSStartupLinkLoaded');

      document.dispatchEvent(new CustomEvent('DOMContentLoaded'));
      await events;

      expect(docDispatch).toHaveBeenCalledTimes(3);
      expect(docDispatch.mock.calls[2][0].type).toBe('CSSLoaded');
      expect(docRemoveListener).toHaveBeenCalledTimes(1);
      expect(mock).toHaveBeenCalledTimes(1);
    });

    it('should wait to call CssLoaded until the assets are loaded', async () => {
      const events = waitForCSSLoaded(mock);
      const fixtures = `
        <link href="one.css" data-startupcss="loading">
        <link href="two.css" data-startupcss="loading">
      `;
      setFixtures(fixtures);

      expect(docAddListener).toHaveBeenCalledTimes(3);
      expect(docDispatch.mock.calls[0][0].type).toBe('CSSStartupLinkLoaded');

      document
        .querySelectorAll('[data-startupcss="loading"]')
        .forEach(elem => elem.setAttribute('data-startupcss', 'loaded'));
      document.dispatchEvent(new CustomEvent('DOMContentLoaded'));
      document.dispatchEvent(new CustomEvent('CSSStartupLinkLoaded'));
      await events;

      expect(docDispatch).toHaveBeenCalledTimes(4);
      expect(docDispatch.mock.calls[3][0].type).toBe('CSSLoaded');
      expect(docRemoveListener).toHaveBeenCalledTimes(1);
      expect(mock).toHaveBeenCalledTimes(1);
    });
  });
});
