import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import htmlNewMilestone from 'test_fixtures/milestones/new-milestone.html';
import mock from 'xhr-mock';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import PasteMarkdownTable from '~/behaviors/markdown/paste_markdown_table';
import dropzoneInput from '~/dropzone_input';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_FILE = new File([], 'somefile.jpg');
TEST_FILE.upload = {};

const TEST_UPLOAD_PATH = `${TEST_HOST}/upload/file`;
const TEST_ERROR_MESSAGE = 'A big error occurred!';
const TEMPLATE = `<form class="gfm-form" data-uploads-path="${TEST_UPLOAD_PATH}">
  <textarea class="js-gfm-input"></textarea>
  <div class="uploading-error-message"></div>
</form>`;

describe('dropzone_input', () => {
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
    });

    afterEach(() => {
      form = null;

      resetHTMLFixture();
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
      axiosMock.onPost().reply(HTTP_STATUS_OK, { link: { markdown: 'foo' } });
      await waitForPromises();
      expect(axiosMock.history.post[0].data.get('file').name).toEqual('test.png');
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

    beforeEach(() => {});

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
});
