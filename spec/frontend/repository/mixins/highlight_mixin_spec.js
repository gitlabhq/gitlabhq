import { shallowMount } from '@vue/test-utils';
import { splitIntoChunks } from '~/vue_shared/components/source_viewer/workers/highlight_utils';
import highlightMixin from '~/repository/mixins/highlight_mixin';
import LineHighlighter from '~/blob/line_highlighter';
import { TEXT_FILE_TYPE } from '~/repository/constants';
import { LINES_PER_CHUNK } from '~/vue_shared/components/source_viewer/constants';

const lineHighlighter = new LineHighlighter();
jest.mock('~/blob/line_highlighter', () => jest.fn().mockReturnValue({ highlightHash: jest.fn() }));
jest.mock('~/vue_shared/components/source_viewer/workers/highlight_utils', () => ({
  splitIntoChunks: jest.fn().mockResolvedValue([]),
}));

const workerMock = { postMessage: jest.fn() };
const onErrorMock = jest.fn();

describe('HighlightMixin', () => {
  let wrapper;
  const hash = '#L50';
  const contentArray = Array.from({ length: 140 }, () => 'newline'); // simulate 140 lines of code
  const rawTextBlob = contentArray.join('\n');
  const languageMock = 'json';

  const createComponent = ({ fileType = TEXT_FILE_TYPE, language = languageMock } = {}) => {
    const simpleViewer = { fileType };

    const dummyComponent = {
      mixins: [highlightMixin],
      inject: {
        highlightWorker: { default: workerMock },
        glFeatures: { default: { highlightJsWorker: true } },
      },
      template: '<div>{{chunks[0]?.highlightedContent}}</div>',
      created() {
        this.initHighlightWorker({ rawTextBlob, simpleViewer, language, fileType });
      },
      methods: { onError: onErrorMock },
    };

    wrapper = shallowMount(dummyComponent, { mocks: { $route: { hash } } });
  };

  beforeEach(() => createComponent());

  describe('initHighlightWorker', () => {
    const firstSeventyLines = contentArray.slice(0, LINES_PER_CHUNK).join('\n');

    it('does not instruct worker if file is not a JSON file', () => {
      workerMock.postMessage.mockClear();
      createComponent({ language: 'javascript' });

      expect(workerMock.postMessage).not.toHaveBeenCalled();
    });

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

  describe('worker message handling', () => {
    const CHUNK_MOCK = { startingFrom: 0, totalLines: 70, highlightedContent: 'some content' };

    beforeEach(() => workerMock.onmessage({ data: [CHUNK_MOCK] }));

    it('updates the chunks data', () => {
      expect(wrapper.text()).toBe(CHUNK_MOCK.highlightedContent);
    });

    it('highlights hash', () => {
      expect(lineHighlighter.highlightHash).toHaveBeenCalledWith(hash);
    });
  });
});
