/* eslint-disable no-new */

import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setTestTimeout } from 'helpers/timeout';
import BlobViewer from '~/blob/viewer/index';
import axios from '~/lib/utils/axios_utils';

const execImmediately = (callback) => {
  callback();
};

describe('Blob viewer', () => {
  let blob;
  let mock;

  const jQueryMock = {
    tooltip: jest.fn(),
  };

  setTestTimeout(2000);

  beforeEach(() => {
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);
    $.fn.extend(jQueryMock);
    mock = new MockAdapter(axios);

    loadFixtures('blob/show_readme.html');
    $('#modal-upload-blob').remove();

    mock.onGet(/blob\/master\/README\.md/).reply(200, {
      html: '<div>testing</div>',
    });

    blob = new BlobViewer();
  });

  afterEach(() => {
    mock.restore();
    window.location.hash = '';
  });

  it('loads source file after switching views', (done) => {
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

  it('loads source file when line number is in hash', (done) => {
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
    const asyncClick = async () => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      await axios.waitForAll();
    };

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
    let copyButtonTooltip;

    beforeEach(() => {
      copyButton = document.querySelector('.js-copy-blob-source-btn');
      copyButtonTooltip = document.querySelector('.js-copy-blob-source-btn-tooltip');
    });

    it('disabled on load', () => {
      expect(copyButton.classList.contains('disabled')).toBeTruthy();
    });

    it('has tooltip when disabled', () => {
      expect(copyButtonTooltip.getAttribute('title')).toBe(
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

    it('enables after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setImmediate(() => {
        expect(copyButton.classList.contains('disabled')).toBeFalsy();

        done();
      });
    });

    it('updates tooltip after switching to simple view', (done) => {
      document.querySelector('.js-blob-viewer-switch-btn[data-viewer="simple"]').click();

      setImmediate(() => {
        expect(copyButtonTooltip.getAttribute('title')).toBe('Copy file contents');

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

      expect(simpleBtn.classList.contains('selected')).toBeTruthy();

      expect(simpleBtn.blur).toHaveBeenCalled();
    });

    it('makes request for initial view', () => {
      expect(mock.history).toMatchObject({
        get: [{ url: expect.stringMatching(/README\.md\?.*viewer=rich/) }],
      });
    });

    describe.each`
      views
      ${['simple']}
      ${['simple', 'rich']}
    `('when view switches to $views', ({ views }) => {
      beforeEach(async () => {
        views.forEach((view) => blob.switchToViewer(view));
        await axios.waitForAll();
      });

      it('sends 1 AJAX request for new view', async () => {
        expect(mock.history).toMatchObject({
          get: [
            { url: expect.stringMatching(/README\.md\?.*viewer=rich/) },
            { url: expect.stringMatching(/README\.md\?.*viewer=simple/) },
          ],
        });
      });
    });
  });
});
