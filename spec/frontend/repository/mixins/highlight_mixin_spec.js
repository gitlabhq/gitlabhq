import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { splitIntoChunks } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import highlightMixin from '~/repository/mixins/highlight_mixin';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEXT_FILE_TYPE } from '~/repository/constants';
import {
  LINES_PER_CHUNK,
  EVENT_ACTION,
  EVENT_LABEL_FALLBACK,
} from '~/vue_shared/components/source_viewer/constants';
import Tracking from '~/tracking';

jest.mock('~/vue_shared/components/source_viewer/workers/highlight_utils', () => ({
  splitIntoChunks: jest.fn().mockResolvedValue([]),
}));

const mockAxios = new MockAdapter(axios);
const workerMock = { postMessage: jest.fn() };
const onErrorMock = jest.fn();

describe('HighlightMixin', () => {
  let wrapper;
  let dummyComponent;
  const hash = '#L50-100';
  const contentArray = Array.from({ length: 140 }, () => 'newline'); // simulate 140 lines of code
  const rawTextBlob = contentArray.join('\n');
  const languageMock = 'json';
  const nameMock = 'test.json';

  const createComponent = (
    {
      fileType = TEXT_FILE_TYPE,
      language = languageMock,
      name = nameMock,
      externalStorageUrl,
      rawPath,
    } = {},
    isUsingLfs = false,
  ) => {
    const simpleViewer = { fileType };

    dummyComponent = {
      mixins: [highlightMixin],
      inject: {
        highlightWorker: { default: workerMock },
      },
      template: `<div>
          <div v-for="(chunk, index) in chunks">
            {{chunk.highlightedContent}}
            highlighted({{index}}): {{chunk.isHighlighted}}
          </div>
        </div>`,
      created() {
        this.initHighlightWorker(
          { rawTextBlob, simpleViewer, language, name, fileType, externalStorageUrl, rawPath },
          isUsingLfs,
        );
      },
      methods: { onError: onErrorMock },
    };

    wrapper = shallowMount(dummyComponent, { mocks: { $route: { hash } } });
  };

  beforeEach(() => createComponent());

  describe('initHighlightWorker', () => {
    const firstSeventyLines = contentArray.slice(0, LINES_PER_CHUNK).join('\n');

    it('generates a chunk for the first 70 lines of raw text', () => {
      expect(splitIntoChunks).toHaveBeenCalledWith(languageMock, firstSeventyLines);
    });

    it('calls postMessage on the worker', () => {
      expect(workerMock.postMessage.mock.calls.length).toBe(2);

      // first call instructs worker to highlight the first 70 lines
      expect(workerMock.postMessage.mock.calls[0][0]).toMatchObject({
        content: firstSeventyLines,
        language: languageMock,
      });

      // second call instructs worker to highlight all of the lines
      expect(workerMock.postMessage.mock.calls[1][0]).toMatchObject({
        content: rawTextBlob,
        language: languageMock,
        fileType: TEXT_FILE_TYPE,
      });
    });
  });

  describe('auto-detects if a language cannot be loaded', () => {
    const unknownLanguage = 'some_unknown_language';
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      createComponent({ language: unknownLanguage });
    });

    it('emits a tracking event for the fallback', () => {
      const eventData = { label: EVENT_LABEL_FALLBACK, property: unknownLanguage };
      expect(Tracking.event).toHaveBeenCalledWith(undefined, EVENT_ACTION, eventData);
    });

    it('calls the onError method', () => {
      expect(onErrorMock).toHaveBeenCalled();
    });
  });

  describe('worker message handling', () => {
    const highlightedContent = 'some content';
    const CHUNK_1_MOCK = { startingFrom: 0, totalLines: 70, highlightedContent };
    const CHUNK_2_MOCK = { startingFrom: 71, totalLines: 70, highlightedContent };

    beforeEach(() => workerMock.onmessage({ data: [CHUNK_1_MOCK, CHUNK_2_MOCK] }));

    it('updates the chunks data', () => {
      expect(wrapper.text()).toContain(CHUNK_1_MOCK.highlightedContent);
    });

    it('ensures the hash gets highlighted by setting isHighlighted to true on chunks that fall in the range of the hash', () => {
      expect(wrapper.text()).toContain('highlighted(0): true');
      expect(wrapper.text()).toContain('highlighted(1): true');
    });

    describe('when order of events are incorrect', () => {
      it('renders the correct data', async () => {
        const chunk1 = { highlightedContent: 'chunk 1 content' };
        const chunk2 = { highlightedContent: 'chunk 2 content' };

        workerMock.onmessage({ data: [chunk1, chunk2] });
        workerMock.onmessage({ data: [chunk2] });

        await nextTick();

        expect(wrapper.text()).toContain(chunk1.highlightedContent);
      });
    });
  });

  describe('LFS blobs', () => {
    const rawPath = '/org/project/-/raw/file.xml';
    const externalStorageUrl = 'http://127.0.0.1:9000/lfs-objects/91/12/1341234';
    const mockParams = { content: rawTextBlob, language: languageMock, fileType: TEXT_FILE_TYPE };

    afterEach(() => mockAxios.reset());

    it('Uses externalStorageUrl to fetch content if present', async () => {
      mockAxios.onGet(externalStorageUrl).replyOnce(HTTP_STATUS_OK, rawTextBlob);
      createComponent({ rawPath, externalStorageUrl }, true);
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toBe(externalStorageUrl);
      expect(workerMock.postMessage).toHaveBeenCalledWith(mockParams);
    });

    it('Falls back to rawPath to fetch content', async () => {
      mockAxios.onGet(rawPath).replyOnce(HTTP_STATUS_OK, rawTextBlob);
      createComponent({ rawPath }, true);
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toBe(rawPath);
      expect(workerMock.postMessage).toHaveBeenCalledWith(mockParams);
    });
  });

  describe('Gleam language handling', () => {
    beforeEach(() => workerMock.postMessage.mockClear());

    it('sets language to gleam for .gleam files regardless of passed language', () => {
      createComponent({ language: 'plaintext', name: 'test.gleam' });

      expect(workerMock.postMessage.mock.calls[0][0]).toMatchObject({
        language: 'gleam',
      });
    });
  });
});
