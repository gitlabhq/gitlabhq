/* eslint-disable no-new */

import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import BlobViewer from '~/blob/viewer/index';
import axios from '~/lib/utils/axios_utils';

describe('Blob viewer', () => {
  let blob;
  let mock;

  const jQueryMock = {
    tooltip: jest.fn(),
  };

  preloadFixtures('snippets/show.html');

  beforeEach(() => {
    $.fn.extend(jQueryMock);
    mock = new MockAdapter(axios);

    loadFixtures('snippets/show.html');
    $('#modal-upload-blob').remove();

    blob = new BlobViewer();

    mock.onGet('http://test.host/-/snippets/1.json?viewer=rich').reply(200, {
      html: '<div>testing</div>',
    });

    mock.onGet('http://test.host/-/snippets/1.json?viewer=simple').reply(200, {
      html: '<div>testing</div>',
    });

    jest.spyOn(axios, 'get');
  });

  afterEach(() => {
    mock.restore();
    window.location.hash = '';
  });

  it('loads source file after switching views', done => {
    document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

    setImmediate(() => {
      expect(
        document
          .querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('loads source file when line number is in hash', done => {
    window.location.hash = '#L1';

    new BlobViewer();

    setImmediate(() => {
      expect(
        document
          .querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]')
          .classList.contains('hidden'),
      ).toBeFalsy();

      done();
    });
  });

  it('doesnt reload file if already loaded', () => {
    const asyncClick = () =>
      new Promise(resolve => {
        document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

        setImmediate(resolve);
      });

    return asyncClick()
      .then(() => asyncClick())
      .then(() => {
        expect(
          document.querySelector('.blob-viewer[data-type="simple"]').getAttribute('data-loaded'),
        ).toBe('true');
      });
  });

  describe('copy blob button', () => {
    let copyButton;

    beforeEach(() => {
      copyButton = document.querySelector('.js-copy-blob-source-btn');
    });

    it('disabled on load', () => {
      expect(copyButton.classList.contains('disabled')).toBeTruthy();
    });

    it('has tooltip when disabled', () => {
      expect(copyButton.getAttribute('title')).toBe(
        'Switch to the source to copy the file contents',
      );
    });

    it('is blurred when clicked and disabled', () => {
      jest.spyOn(copyButton, 'blur').mockImplementation(() => {});

      copyButton.click();

      expect(copyButton.blur).toHaveBeenCalled();
    });

    it('is not blurred when clicked and not disabled', () => {
      jest.spyOn(copyButton, 'blur').mockImplementation(() => {});

      copyButton.classList.remove('disabled');
      copyButton.click();

      expect(copyButton.blur).not.toHaveBeenCalled();
    });

    it('enables after switching to simple view', done => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setImmediate(() => {
        expect(copyButton.classList.contains('disabled')).toBeFalsy();

        done();
      });
    });

    it('updates tooltip after switching to simple view', done => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setImmediate(() => {
        expect(copyButton.getAttribute('title')).toBe('Copy file contents');

        done();
      });
    });
  });

  describe('switchToViewer', () => {
    it('removes active class from old viewer button', () => {
      blob.switchToViewer('simple');

      expect(
        document.querySelector('.js-blob-viewer-switch-btn.active[data-viewer="rich"]'),
      ).toBeNull();
    });

    it('adds active class to new viewer button', () => {
      const simpleBtn = document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]');

      jest.spyOn(simpleBtn, 'blur').mockImplementation(() => {});

      blob.switchToViewer('simple');

      expect(simpleBtn.classList.contains('active')).toBeTruthy();

      expect(simpleBtn.blur).toHaveBeenCalled();
    });

    it('sends AJAX request when switching to simple view', () => {
      blob.switchToViewer('simple');

      expect(axios.get).toHaveBeenCalled();
    });

    it('does not send AJAX request when switching to rich view', () => {
      blob.switchToViewer('simple');
      blob.switchToViewer('rich');

      expect(axios.get.mock.calls.length).toBe(1);
    });
  });
});
