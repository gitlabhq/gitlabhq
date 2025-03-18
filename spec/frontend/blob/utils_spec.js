import * as utils from '~/blob/utils';
import { TEST_HOST } from 'helpers/test_constants';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('Blob utilities', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  describe('getPageParamValue', () => {
    it('returns empty string if no perPage parameter is provided', () => {
      const pageParamValue = utils.getPageParamValue(5);
      expect(pageParamValue).toEqual('');
    });

    it('returns empty string if page is equal 1', () => {
      const pageParamValue = utils.getPageParamValue(1000, 1000);
      expect(pageParamValue).toEqual('');
    });

    it('returns correct page parameter value', () => {
      const pageParamValue = utils.getPageParamValue(1001, 1000);
      expect(pageParamValue).toEqual(2);
    });

    it('accepts strings as a parameter and returns correct result', () => {
      const pageParamValue = utils.getPageParamValue('1001', '1000');
      expect(pageParamValue).toEqual(2);
    });
  });

  describe('getPageSearchString', () => {
    it('returns empty search string if page parameter is empty value', () => {
      const path = utils.getPageSearchString('/blamePath', '');
      expect(path).toEqual('');
    });

    it('returns correct search string if value is provided', () => {
      const searchString = utils.getPageSearchString('http://project/blamePath', 3);
      expect(searchString).toEqual('?page=3');
    });
  });

  describe('moveToFilePermalink', () => {
    const initialTitle = 'Title · Test';
    let windowHistorySpy;

    beforeEach(() => {
      windowHistorySpy = jest.spyOn(window.history, 'pushState');
      setWindowLocation(TEST_HOST);
      document.title = initialTitle;
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('should do nothing when permalink element does not exist', () => {
      utils.moveToFilePermalink();

      expect(windowHistorySpy).not.toHaveBeenCalled();
      expect(document.title).toMatch(initialTitle);
    });

    it('should do nothing when permalink element exists but has no href', () => {
      document.body.innerHTML = `
        <div class="js-data-file-blob-permalink-url">
          <a data-testid="permalink"></a>
        </div>
      `;

      utils.moveToFilePermalink();

      expect(windowHistorySpy).not.toHaveBeenCalled();
      expect(document.title).toMatch(initialTitle);
    });

    it('should not update history when URL is not different', () => {
      const url = `${TEST_HOST}/test/permalink`;
      document.body.innerHTML = `
         <a data-testid="permalink" class="js-data-file-blob-permalink-url" href="${url}"></a>
      `;
      setWindowLocation(url);

      utils.moveToFilePermalink();

      expect(windowHistorySpy).not.toHaveBeenCalled();
      expect(document.title).toMatch(initialTitle);
    });

    it('should update history and title when URL is different and contains SHA', () => {
      const testSha = 'ad9be38573f9ee4c4daec22673478c2dd1d81cd8';
      document.body.innerHTML = `
         <a class="js-data-file-blob-permalink-url" data-testid="permalink" href="/test/permalink/${testSha}"></a>
      `;

      utils.moveToFilePermalink();

      expect(windowHistorySpy).toHaveBeenCalledWith({}, initialTitle, `/test/permalink/${testSha}`);
      expect(document.title).toMatch(`Title · ${testSha}`);
    });

    it('should update history but not title when URL is different but contains no SHA', () => {
      document.body.innerHTML = `
        <a class="js-data-file-blob-permalink-url" data-testid="permalink" href="/test/permalink"></a>
      `;

      utils.moveToFilePermalink();

      expect(windowHistorySpy).toHaveBeenCalledWith({}, initialTitle, `/test/permalink`);
      expect(document.title).toMatch(initialTitle);
    });
  });

  describe('shortcircuitPermalinkButton', () => {
    let permalinkElement;

    beforeEach(() => {
      permalinkElement = document.createElement('a');
      permalinkElement.dataset.testid = 'permalink';
      permalinkElement.className = 'js-data-file-blob-permalink-url';

      document.body.appendChild(permalinkElement);
    });

    afterEach(() => {
      document.body.innerHTML = '';
      jest.clearAllMocks();
    });

    it('attaches click event listener to permalink element', () => {
      const addEventListenerSpy = jest.spyOn(permalinkElement, 'addEventListener');

      utils.shortcircuitPermalinkButton();

      expect(addEventListenerSpy).toHaveBeenCalledWith('click', expect.any(Function));
    });

    it('does nothing if permalink element is not found', () => {
      document.body.innerHTML = '';

      expect(() => {
        utils.shortcircuitPermalinkButton();
      }).not.toThrow();
    });

    describe('click handling', () => {
      beforeEach(() => {
        utils.shortcircuitPermalinkButton();
      });

      afterEach(() => {
        jest.restoreAllMocks();
      });

      it('prevents default and calls moveToFilePermalink for normal click', () => {
        const clickEvent = new MouseEvent('click');
        const preventDefaultSpy = jest.spyOn(clickEvent, 'preventDefault');
        const querySelectorSpy = jest.spyOn(document, 'querySelector');

        permalinkElement.dispatchEvent(clickEvent);

        expect(preventDefaultSpy).toHaveBeenCalled();
        // Because we can't mock moveToFilePermalink, we are asserting it's being called by
        // asserting that the first line inside the method is being executed:
        expect(querySelectorSpy).toHaveBeenCalledWith('.js-data-file-blob-permalink-url');
      });

      it.each([
        ['ctrl', { ctrlKey: true }],
        ['meta', { metaKey: true }],
        ['shift', { shiftKey: true }],
      ])('does not prevent default or call moveToFilePermalink for %s click', (_, modifiers) => {
        const clickEvent = new MouseEvent('click', {
          ...modifiers,
        });
        const preventDefaultSpy = jest.spyOn(clickEvent, 'preventDefault');
        const querySelectorSpy = jest.spyOn(document, 'querySelector');

        permalinkElement.dispatchEvent(clickEvent);

        expect(preventDefaultSpy).not.toHaveBeenCalled();
        // Because we can't mock moveToFilePermalink, we are asserting it's being called by
        // asserting that the first line inside the method is being executed:
        expect(querySelectorSpy).not.toHaveBeenCalled();
      });
    });
  });
});
