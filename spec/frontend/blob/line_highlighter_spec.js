/* eslint-disable no-return-assign, no-new, no-underscore-dangle */
import htmlStaticLineHighlighter from 'test_fixtures_static/line_highlighter.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import LineHighlighter from '~/blob/line_highlighter';
import { updateHash } from '~/blob/state';
import * as utils from '~/lib/utils/common_utils';

jest.mock('~/blob/state');

describe('LineHighlighter', () => {
  const testContext = {};

  const clickLine = (number, eventData = {}) => {
    if (Object.keys(eventData).length === 0) {
      return document.querySelector(`#L${number}`).click();
    }
    const e = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      ...eventData,
    });
    return document.querySelector(`#L${number}`).dispatchEvent(e);
  };

  beforeEach(() => {
    setHTMLFixture(htmlStaticLineHighlighter);
    testContext.class = new LineHighlighter();
    testContext.css = testContext.class.highlightLineClass;
    return (testContext.spies = {
      __setLocationHash__: jest
        .spyOn(testContext.class, '__setLocationHash__')
        .mockImplementation(() => {}),
    });
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('behavior', () => {
    it('highlights one line given in the URL hash', () => {
      new LineHighlighter({ hash: '#L13' });

      expect(document.querySelector('#LC13').classList).toContain(testContext.css);
    });

    it('highlights one line given in the URL hash with given CSS class name', () => {
      const hiliter = new LineHighlighter({ hash: '#L13', highlightLineClass: 'hilite' });

      expect(hiliter.highlightLineClass).toBe('hilite');
      expect(document.querySelector('#LC13').classList).toContain('hilite');
      expect(document.querySelector('#LC13').classList).not.toContain('hll');
    });

    it('highlights a range of lines given in the URL hash', () => {
      new LineHighlighter({ hash: '#L5-25' });

      for (let line = 5; line <= 25; line += 1) {
        expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
      }
    });

    it('highlights a range of lines given in the URL hash using GitHub format', () => {
      new LineHighlighter({ hash: '#L5-L25' });

      for (let line = 5; line <= 25; line += 1) {
        expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
      }
    });

    it('scrolls to the first highlighted line on initial load', () => {
      jest.spyOn(utils, 'scrollToElement');
      new LineHighlighter({ hash: '#L5-25' });

      expect(utils.scrollToElement).toHaveBeenCalledWith('#L5', expect.anything());
    });

    it('does not scroll to the first highlighted line when disableScroll is `true`', () => {
      jest.spyOn(utils, 'scrollToElement');
      const highlighter = new LineHighlighter();
      const scrollEnabled = false;
      highlighter.highlightHash('#L5-25', scrollEnabled);

      expect(utils.scrollToElement).not.toHaveBeenCalled();
    });

    it('discards click events', () => {
      const clickSpy = jest.fn();

      document.querySelectorAll('a[data-line-number]').forEach((el) => {
        el.addEventListener('click', clickSpy);
      });

      clickLine(13);

      expect(clickSpy.mock.calls[0][0].defaultPrevented).toEqual(true);
    });

    it('handles garbage input from the hash', () => {
      const func = () => {
        return new LineHighlighter({ fileHolderSelector: '#blob-content-holder' });
      };

      expect(func).not.toThrow();
    });

    it('handles hashchange event', () => {
      const highlighter = new LineHighlighter();

      jest.spyOn(highlighter, 'highlightHash').mockImplementation(() => {});

      window.dispatchEvent(new Event('hashchange'), 'L15');

      expect(highlighter.highlightHash).toHaveBeenCalled();
    });
  });

  describe('clickHandler', () => {
    describe('without shiftKey', () => {
      it('highlights one line when clicked', () => {
        clickLine(13);

        expect(document.querySelector('#LC13').classList).toContain(testContext.css);
      });

      it('unhighlights previously highlighted lines', () => {
        clickLine(13);
        clickLine(20);

        expect(document.querySelector('#LC13').classList).not.toContain(testContext.css);
        expect(document.querySelector('#LC20').classList).toContain(testContext.css);
      });

      it('sets the hash', () => {
        const spy = jest.spyOn(testContext.class, 'setHash');
        clickLine(13);

        expect(spy).toHaveBeenCalledWith(13);
      });
    });

    describe('with shiftKey', () => {
      it('sets the hash', () => {
        const spy = jest.spyOn(testContext.class, 'setHash');
        clickLine(13);
        clickLine(20, {
          shiftKey: true,
          bubbles: true,
          cancelable: true,
        });

        expect(spy).toHaveBeenCalledWith(13);
        expect(spy).toHaveBeenCalledWith(13, 20);
      });

      describe('without existing highlight', () => {
        it('highlights the clicked line', () => {
          clickLine(13, {
            shiftKey: true,
          });

          expect(document.querySelector('#LC13').classList).toContain(testContext.css);
          expect(document.querySelectorAll(`.${testContext.css}`).length).toBe(1);
        });

        it('sets the hash', () => {
          const spy = jest.spyOn(testContext.class, 'setHash');
          clickLine(13, {
            shiftKey: true,
          });

          expect(spy).toHaveBeenCalledWith(13);
        });
      });

      describe('with existing single-line highlight', () => {
        it('uses existing line as last line when target is lesser', () => {
          clickLine(20);
          clickLine(15, {
            shiftKey: true,
          });

          expect(document.querySelectorAll(`.${testContext.css}`).length).toBe(6);
          for (let line = 15; line <= 20; line += 1) {
            expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
          }
        });

        it('uses existing line as first line when target is greater', () => {
          clickLine(5);
          clickLine(10, {
            shiftKey: true,
          });

          expect(document.querySelectorAll(`.${testContext.css}`).length).toBe(6);
          for (let line = 5; line <= 10; line += 1) {
            expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
          }
        });
      });

      describe('with existing multi-line highlight', () => {
        beforeEach(() => {
          clickLine(10, {
            shiftKey: true,
          });
          clickLine(13, {
            shiftKey: true,
          });
        });

        it('uses target as first line when it is less than existing first line', () => {
          clickLine(5, {
            shiftKey: true,
          });

          expect(document.querySelectorAll(`.${testContext.css}`).length).toBe(6);
          for (let line = 5; line <= 10; line += 1) {
            expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
          }
        });

        it('uses target as last line when it is greater than existing first line', () => {
          clickLine(15, {
            shiftKey: true,
          });

          expect(document.querySelectorAll(`.${testContext.css}`).length).toBe(6);
          for (let line = 10; line <= 15; line += 1) {
            expect(document.querySelector(`#LC${line}`).classList).toContain(testContext.css);
          }
        });
      });
    });
  });

  describe('hashToRange', () => {
    beforeEach(() => {
      testContext.subject = testContext.class.hashToRange;
    });

    it('extracts a single line number from the hash', () => {
      expect(testContext.subject('#L5')).toEqual([5, null]);
    });

    it('extracts a range of line numbers from the hash', () => {
      expect(testContext.subject('#L5-15')).toEqual([5, 15]);
    });

    it('returns [null, null] when the hash is not a line number', () => {
      expect(testContext.subject('#foo')).toEqual([null, null]);
    });
  });

  describe('highlightLine', () => {
    beforeEach(() => {
      testContext.subject = testContext.class.highlightLine;
    });

    it('highlights the specified line', () => {
      testContext.subject(13);

      expect(document.querySelector('#LC13').classList).toContain(testContext.css);
    });

    it('accepts a String-based number', () => {
      testContext.subject('13');

      expect(document.querySelector('#LC13').classList).toContain(testContext.css);
    });
  });

  describe('setHash', () => {
    beforeEach(() => {
      testContext.subject = testContext.class.setHash;
    });

    it('sets the location hash for a single line', () => {
      testContext.subject(5);

      expect(testContext.spies.__setLocationHash__).toHaveBeenCalledWith('#L5');
    });

    it('sets the location hash for a range', () => {
      testContext.subject(5, 15);

      expect(testContext.spies.__setLocationHash__).toHaveBeenCalledWith('#L5-15');
    });

    it('calls updateHash with the correct hash for a single line', () => {
      testContext.subject(5);

      expect(updateHash).toHaveBeenCalledWith('#L5');
    });

    it('calls updateHash with the correct hash for a range', () => {
      testContext.subject(5, 15);

      expect(updateHash).toHaveBeenCalledWith('#L5-15');
    });
  });
});
