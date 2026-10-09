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
import * as mediaUtils from '~/lib/utils/media_utils';

const TEST_FILE = new File([], 'somefile.jpg');
TEST_FILE.upload = {};

const TEST_UPLOAD_PATH = `${TEST_HOST}/upload/file`;
const TEST_ERROR_MESSAGE = 'A big error occurred!';
const TEMPLATE = `<form class="gfm-form" data-uploads-path="${TEST_UPLOAD_PATH}">
  <textarea class="js-gfm-input"></textarea>
  <div class="uploading-error-message"></div>
</form>`;

describe('dropzone_input', () => {
  beforeEach(() => {
    jest.spyOn(mediaUtils, 'getLimitedMediaDimensions').mockResolvedValue(null);
  });

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
    let axiosMock;

    const triggerPasteEvent = (clipboardData = {}) => {
      const event = $.Event('paste');
      const origEvent = new Event('paste');

      origEvent.clipboardData = clipboardData;
      event.originalEvent = origEvent;

      $('.js-gfm-input').trigger(event);
    };

    const triggerFilesPasteEvent = (files) => {
      const fileList = files.map(
        ({ fileName, mimeType }) => new File([new Blob()], fileName, { type: mimeType }),
      );

      triggerPasteEvent({
        types: ['Files'],
        files: fileList,
        items: fileList.map((file) => ({ kind: 'file', type: file.type, getAsFile: () => file })),
      });
    };

    const triggerFilePasteEvent = (fileName, mimeType) =>
      triggerFilesPasteEvent([{ fileName, mimeType }]);

    const pasteFileAndAwaitUpload = ({ fileName, mimeType, markdown, dimensions = null }) => {
      jest.spyOn(mediaUtils, 'getLimitedMediaDimensions').mockResolvedValue(dimensions);
      axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown } });

      return new Promise((resolve) => {
        $('textarea').on('change', () => resolve(axiosMock));

        triggerFilePasteEvent(fileName, mimeType);
      });
    };

    const uploadedFileNames = () =>
      axiosMock.history.post.map((request) => request.data.get('file').name);

    const textareaValue = () => $('textarea').val();

    beforeEach(() => {
      setHTMLFixture(htmlNewMilestone);

      form = $('#new_milestone');
      form.data('uploads-path', TEST_UPLOAD_PATH);
      dropzoneInput(form);

      // needed for the underlying insertText to work
      document.execCommand = jest.fn(() => false);

      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      form = null;
      axiosMock.restore();
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
      const longFileName = 'a'.repeat(300);

      await pasteFileAndAwaitUpload({
        fileName: longFileName,
        mimeType: 'image/png',
        markdown: '![truncated]',
      });

      expect(uploadedFileNames()[0]).toHaveLength(246);
    });

    it('ignores pasted non-media files', async () => {
      triggerFilePasteEvent('doc.pdf', 'application/pdf');
      await waitForPromises();

      expect(axiosMock.history.post).toHaveLength(0);
      expect(textareaValue()).toBe('');
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

      expect(textareaValue()).toBe('');
    });

    it.each`
      mimeType             | pastedName    | expectedName
      ${'image/png'}       | ${'test.png'} | ${'test.png'}
      ${'video/quicktime'} | ${'test.mov'} | ${'test.mov'}
      ${'image/png'}       | ${''}         | ${'image.png'}
      ${'video/mp4'}       | ${''}         | ${'video.mp4'}
      ${'video/quicktime'} | ${''}         | ${'video.mov'}
      ${'video/webm'}      | ${''}         | ${'video.webm'}
      ${'video/ogg'}       | ${''}         | ${'video.ogv'}
      ${'video/x-m4v'}     | ${''}         | ${'video.m4v'}
      ${'video/x-msvideo'} | ${''}         | ${'video.bin'}
    `(
      'uploads a pasted $mimeType file as $expectedName',
      async ({ mimeType, pastedName, expectedName }) => {
        await pasteFileAndAwaitUpload({
          fileName: pastedName,
          mimeType,
          markdown: '![uploaded]',
        });

        expect(uploadedFileNames()).toEqual([expectedName]);
        expect(textareaValue()).toEqual('![uploaded]');
      },
    );

    it('keeps the placeholder when a pasted file fails to upload', async () => {
      axiosMock.onPost().reply(HTTP_STATUS_BAD_REQUEST, { message: 'nope' });

      triggerFilePasteEvent('test.mp4', 'video/mp4');
      await waitForPromises();

      expect(axiosMock.history.post).toHaveLength(1);
      expect(textareaValue()).toBe('{{test.mp4}}');
    });

    it('uploads every file pasted at once', async () => {
      axiosMock
        .onPost()
        .reply((config) => [
          HTTP_STATUS_OK,
          { link: { markdown: `![${config.data.get('file').name}]` } },
        ]);

      triggerFilesPasteEvent([
        { fileName: 'foo.png', mimeType: 'image/png' },
        { fileName: 'bar.mp4', mimeType: 'video/mp4' },
      ]);
      await waitForPromises();

      expect(uploadedFileNames()).toEqual(['foo.png', 'bar.mp4']);
      expect(textareaValue()).toEqual('![foo.png]![bar.mp4]');
    });

    it('keeps the placeholder for a file that fails while another uploads', async () => {
      axiosMock
        .onPost()
        .reply((config) =>
          config.data.get('file').name === 'foo.png'
            ? [HTTP_STATUS_OK, { link: { markdown: '![foo]' } }]
            : [HTTP_STATUS_BAD_REQUEST, { message: 'nope' }],
        );

      triggerFilesPasteEvent([
        { fileName: 'foo.png', mimeType: 'image/png' },
        { fileName: 'bar.mp4', mimeType: 'video/mp4' },
      ]);
      await waitForPromises();

      expect(textareaValue()).toEqual('![foo]{{bar.mp4}}');
    });

    it('displays width and height for media', async () => {
      await pasteFileAndAwaitUpload({
        fileName: 'test.png',
        mimeType: 'image/png',
        markdown: '![test]',
        dimensions: { width: 663, height: 325 },
      });

      expect(uploadedFileNames()).toEqual(['test.png']);
      expect(textareaValue()).toEqual('![test]{width=663 height=325}');
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

        axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: `![${fileName}]` } });
        triggerFilePasteEvent(fileName, 'image/png');
      });

      expect(textareaValue()).toEqual('');
      expect(execCommandMock.mock.calls).toHaveLength(2);
      expect(execCommandMock.mock.calls[1][2]).toEqual(`![${fileName}]`);
    });
  });

  describe('drag and drop file upload', () => {
    let form;
    let dropzone;

    const dropFile = (file) => {
      const dragEvent = new DragEvent('drop');
      dragEvent.dataTransfer = { files: [file] };
      dropzone.drop(dragEvent);
    };

    beforeEach(() => {
      mock.setup();
      form = $(TEMPLATE);
      dropzone = dropzoneInput(form);
      document.execCommand = jest.fn();
    });

    afterEach(() => {
      mock.teardown();
    });

    it('applies retina dimensions to dropped retina images', async () => {
      jest
        .spyOn(mediaUtils, 'getLimitedMediaDimensions')
        .mockResolvedValue({ width: 663, height: 325 });
      const mockFile = new File(['foo'], 'retina.png', { type: 'image/png' });

      mock.post(TEST_UPLOAD_PATH, {
        status: HTTP_STATUS_OK,
        body: JSON.stringify({
          link: {
            url: '/uploads/retina.png',
            markdown: '![retina.png]',
          },
        }),
        headers: { 'Content-Type': 'application/json' },
      });

      dropFile(mockFile);

      // run dropzone scheduler
      jest.runAllTimers();
      // wait for XHR response and getLimitedImageDimensions to resolve
      await waitForPromises();

      expect($(form).find('textarea').val()).toContain('{width=663 height=325}');
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
