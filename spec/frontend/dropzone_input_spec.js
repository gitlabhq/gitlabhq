import fs from 'fs';
import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import mock from 'xhr-mock';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import PasteMarkdownTable from '~/behaviors/markdown/paste_markdown_table';
import dropzoneInput from '~/dropzone_input';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import htmlNewMilestone from 'test_fixtures_static/textarea.html';

const TEST_FILE = new File([], 'somefile.jpg');
TEST_FILE.upload = {};

const TEST_UPLOAD_PATH = `${TEST_HOST}/upload/file`;
const TEST_ERROR_MESSAGE = 'A big error occurred!';
const TEMPLATE = `<form class="gfm-form" data-uploads-path="${TEST_UPLOAD_PATH}">
  <textarea class="js-gfm-input"></textarea>
  <div class="uploading-error-message"></div>
</form>`;

const RETINA_IMAGE = fs.readFileSync('spec/fixtures/retina_image.png');

describe('dropzone_input', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  it('returns null when failed to initialize', () => {
    const dropzone = dropzoneInput($('<form class="gfm-form"></form>'));

    expect(dropzone).toBeNull();
  });

  it('returns valid dropzone when successfully initialize', () => {
    const dropzone = dropzoneInput($(TEMPLATE));

    expect(dropzone).toMatchObject({
      version: expect.any(String),
    });
  });

  describe('handlePaste', () => {
    let form;

    const triggerPasteEvent = (clipboardData = {}) => {
      const event = $.Event('paste');
      const origEvent = new Event('paste');

      origEvent.clipboardData = clipboardData;
      event.originalEvent = origEvent;

      $('.js-gfm-input').trigger(event);
    };

    beforeEach(() => {
      setHTMLFixture(htmlNewMilestone);

      form = $('#new_milestone');
      form.data('uploads-path', TEST_UPLOAD_PATH);
      dropzoneInput(form);

      // needed for the underlying insertText to work
      document.execCommand = jest.fn(() => false);
    });

    afterEach(() => {
      form = null;
    });

    it('pastes Markdown tables', () => {
      jest.spyOn(PasteMarkdownTable.prototype, 'isTable');
      jest.spyOn(PasteMarkdownTable.prototype, 'convertToTableMarkdown');

      triggerPasteEvent({
        types: ['text/plain', 'text/html'],
        getData: () => '<table><tr><td>Hello World</td></tr></table>',
        items: [],
      });

      expect(PasteMarkdownTable.prototype.isTable).toHaveBeenCalled();
      expect(PasteMarkdownTable.prototype.convertToTableMarkdown).toHaveBeenCalled();
    });

    it('passes truncated long filename to post request', async () => {
      const axiosMock = new MockAdapter(axios);
      const longFileName = 'a'.repeat(300);

      triggerPasteEvent({
        types: ['text/plain', 'text/html', 'text/rtf', 'Files'],
        getData: () => longFileName,
        files: [new File([new Blob()], longFileName, { type: 'image/png' })],
        items: [
          {
            kind: 'file',
            type: 'image/png',
            getAsFile: () => new Blob(),
          },
        ],
      });

      axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: 'foo' } });
      await waitForPromises();
      expect(axiosMock.history.post[0].data.get('file').name).toHaveLength(246);
    });

    it('disables generated image file when clipboardData have both image and text', () => {
      const TEST_PLAIN_TEXT = 'This wording is a plain text.';
      triggerPasteEvent({
        types: ['text/plain', 'Files'],
        getData: () => TEST_PLAIN_TEXT,
        items: [
          {
            kind: 'text',
            type: 'text/plain',
          },
          {
            kind: 'file',
            type: 'image/png',
            getAsFile: () => new Blob(),
          },
        ],
      });

      expect(form.find('.js-gfm-input')[0].value).toBe('');
    });

    it('display original file name in comment box', async () => {
      await new Promise((resolve) => {
        const axiosMock = new MockAdapter(axios);
        triggerPasteEvent({
          types: ['Files'],
          files: [new File([new Blob()], 'test.png', { type: 'image/png' })],
          items: [
            {
              kind: 'file',
              type: 'image/png',
              getAsFile: () => new Blob(),
            },
          ],
        });

        $('textarea').on('change', () => {
          expect(axiosMock.history.post[0].data.get('file').name).toEqual('test.png');
          expect($('textarea').val()).toEqual('![test.png]');

          resolve();
        });

        axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test.png]' } });
      });
    });

    it('display width and height for retina images', async () => {
      await new Promise((resolve) => {
        const axiosMock = new MockAdapter(axios);
        triggerPasteEvent({
          types: ['Files'],
          files: [new File([RETINA_IMAGE], 'test.png', { type: 'image/png' })],
          items: [
            {
              kind: 'file',
              type: 'image/png',
              getAsFile: () => new Blob(),
            },
          ],
        });

        $('textarea').on('change', () => {
          expect(axiosMock.history.post[0].data.get('file').name).toEqual('test.png');
          expect($('textarea').val()).toEqual('![test.png]{width=663 height=325}');

          resolve();
        });

        axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: '![test.png]' } });
      });
    });

    it('preserves undo history', async () => {
      let execCommandMock;
      const fileName = 'undo-file.png';

      await new Promise((resolve) => {
        let counter = 0;
        execCommandMock = jest.fn(() => {
          // The counter is added as execCommand is called twice during paste:
          // 1. With {{undo-file.png}} while the file is being uploaded
          // 2. With ![undo-file.png] after the upload is finished
          counter += 1;
          if (counter >= 2) {
            resolve();
            return true;
          }
          return true;
        });
        document.execCommand = execCommandMock;

        const axiosMock = new MockAdapter(axios);
        axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: `![${fileName}]` } });
        triggerPasteEvent({
          types: ['Files'],
          files: [new File([new Blob()], fileName, { type: 'image/png' })],
          items: [
            {
              kind: 'file',
              type: 'image/png',
              getAsFile: () => new Blob(),
            },
          ],
        });
      });

      expect($('textarea').val()).toEqual('');
      expect(execCommandMock.mock.calls).toHaveLength(2);
      expect(execCommandMock.mock.calls[1][2]).toEqual(`![${fileName}]`);
    });
  });

  describe('shows error message', () => {
    let form;
    let dropzone;

    beforeEach(() => {
      mock.setup();

      form = $(TEMPLATE);

      dropzone = dropzoneInput(form);
    });

    afterEach(() => {
      mock.teardown();
    });

    it.each`
      responseType          | responseBody
      ${'application/json'} | ${JSON.stringify({ message: TEST_ERROR_MESSAGE })}
      ${'text/plain'}       | ${TEST_ERROR_MESSAGE}
    `('when AJAX fails with json', ({ responseType, responseBody }) => {
      mock.post(TEST_UPLOAD_PATH, {
        status: HTTP_STATUS_BAD_REQUEST,
        body: responseBody,
        headers: { 'Content-Type': responseType },
      });

      dropzone.processFile(TEST_FILE);

      return waitForPromises().then(() => {
        expect(form.find('.uploading-error-message').text()).toEqual(TEST_ERROR_MESSAGE);
      });
    });
  });

  describe('clickable element', () => {
    let form;

    beforeEach(() => {
      jest.spyOn($.fn, 'dropzone');
      setHTMLFixture(TEMPLATE);
      form = $('form');
    });

    describe('if attach file button exists', () => {
      let attachFileButton;

      beforeEach(() => {
        attachFileButton = document.createElement('button');
        attachFileButton.dataset.buttonType = 'attach-file';
        document.body.querySelector('form').appendChild(attachFileButton);
      });

      it('passes attach file button as `clickable` to dropzone', () => {
        dropzoneInput(form);
        expect($.fn.dropzone.mock.calls[0][0].clickable).toEqual(attachFileButton);
      });
    });

    describe('if attach file button does not exist', () => {
      it('passes attach file button as `clickable`, if it exists', () => {
        dropzoneInput(form);
        expect($.fn.dropzone.mock.calls[0][0].clickable).toEqual(true);
      });
    });
  });
});
