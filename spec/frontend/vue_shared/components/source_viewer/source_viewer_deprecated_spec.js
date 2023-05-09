import hljs from 'highlight.js/lib/core';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer_deprecated.vue';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk_deprecated.vue';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  EVENT_LABEL_FALLBACK,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
  LINES_PER_CHUNK,
  LEGACY_FALLBACKS,
} from '~/vue_shared/components/source_viewer/constants';
import waitForPromises from 'helpers/wait_for_promises';
import LineHighlighter from '~/blob/line_highlighter';
import eventHub from '~/notes/event_hub';
import Tracking from '~/tracking';

jest.mock('~/blob/line_highlighter');
jest.mock('highlight.js/lib/core');
jest.mock('~/vue_shared/components/source_viewer/plugins/index');
Vue.use(VueRouter);
const router = new VueRouter();

const generateContent = (content, totalLines = 1, delimiter = '\n') => {
  let generatedContent = '';
  for (let i = 0; i < totalLines; i += 1) {
    generatedContent += `Line: ${i + 1} = ${content}${delimiter}`;
  }
  return generatedContent;
};

const execImmediately = (callback) => callback();

describe('Source Viewer component', () => {
  let wrapper;
  const language = 'docker';
  const mappedLanguage = ROUGE_TO_HLJS_LANGUAGE_MAP[language];
  const chunk1 = generateContent('// Some source code 1', 70);
  const chunk2 = generateContent('// Some source code 2', 70);
  const chunk3 = generateContent('// Some source code 3', 70, '\r\n');
  const chunk3Result = generateContent('// Some source code 3', 70, '\n');
  const content = chunk1 + chunk2 + chunk3;
  const path = 'some/path.js';
  const blamePath = 'some/blame/path.js';
  const fileType = 'javascript';
  const DEFAULT_BLOB_DATA = { language, rawTextBlob: content, path, blamePath, fileType };
  const highlightedContent = `<span data-testid='test-highlighted' id='LC1'>${content}</span><span id='LC2'></span>`;

  const createComponent = async (blob = {}) => {
    wrapper = shallowMountExtended(SourceViewer, {
      router,
      propsData: { blob: { ...DEFAULT_BLOB_DATA, ...blob } },
    });
    await waitForPromises();
  };

  const findChunks = () => wrapper.findAllComponents(Chunk);

  beforeEach(() => {
    hljs.highlight.mockImplementation(() => ({ value: highlightedContent }));
    hljs.highlightAuto.mockImplementation(() => ({ value: highlightedContent }));
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);
    jest.spyOn(eventHub, '$emit');
    jest.spyOn(Tracking, 'event');

    return createComponent();
  });

  describe('event tracking', () => {
    it('fires a tracking event when the component is created', () => {
      const eventData = { label: EVENT_LABEL_VIEWER, property: language };
      expect(Tracking.event).toHaveBeenCalledWith(undefined, EVENT_ACTION, eventData);
    });

    it('does not emit an error event when the language is supported', () => {
      expect(wrapper.emitted('error')).toBeUndefined();
    });

    it('fires a tracking event and emits an error when the language is not supported', () => {
      const unsupportedLanguage = 'apex';
      const eventData = { label: EVENT_LABEL_FALLBACK, property: unsupportedLanguage };
      createComponent({ language: unsupportedLanguage });

      expect(Tracking.event).toHaveBeenCalledWith(undefined, EVENT_ACTION, eventData);
      expect(wrapper.emitted('error')).toHaveLength(1);
    });
  });

  describe('legacy fallbacks', () => {
    it.each(LEGACY_FALLBACKS)(
      'tracks a fallback event and emits an error when viewing %s files',
      (fallbackLanguage) => {
        const eventData = { label: EVENT_LABEL_FALLBACK, property: fallbackLanguage };
        createComponent({ language: fallbackLanguage });

        expect(Tracking.event).toHaveBeenCalledWith(undefined, EVENT_ACTION, eventData);
        expect(wrapper.emitted('error')).toHaveLength(1);
      },
    );
  });

  describe('highlight.js', () => {
    beforeEach(() => createComponent({ language: mappedLanguage }));

    it('registers our plugins for Highlight.js', () => {
      expect(registerPlugins).toHaveBeenCalledWith(hljs, fileType, content);
    });

    it('registers the language definition', async () => {
      const languageDefinition = await import(`highlight.js/lib/languages/${mappedLanguage}`);

      expect(hljs.registerLanguage).toHaveBeenCalledWith(
        mappedLanguage,
        languageDefinition.default,
      );
    });

    it('registers json language definition if fileType is package_json', async () => {
      await createComponent({ language: 'json', fileType: 'package_json' });
      const languageDefinition = await import(`highlight.js/lib/languages/json`);

      expect(hljs.registerLanguage).toHaveBeenCalledWith('json', languageDefinition.default);
    });

    it('correctly maps languages starting with uppercase', async () => {
      await createComponent({ language: 'Ruby' });
      const languageDefinition = await import(`highlight.js/lib/languages/ruby`);

      expect(hljs.registerLanguage).toHaveBeenCalledWith('ruby', languageDefinition.default);
    });

    it('highlights the first chunk', () => {
      expect(hljs.highlight).toHaveBeenCalledWith(chunk1.trim(), { language: mappedLanguage });
      expect(findChunks().at(0).props('isFirstChunk')).toBe(true);
    });

    describe('auto-detects if a language cannot be loaded', () => {
      beforeEach(() => createComponent({ language: 'some_unknown_language' }));

      it('highlights the content with auto-detection', () => {
        expect(hljs.highlightAuto).toHaveBeenCalledWith(chunk1.trim());
      });
    });
  });

  describe('rendering', () => {
    it.each`
      chunkIndex | chunkContent    | totalChunks
      ${0}       | ${chunk1}       | ${0}
      ${1}       | ${chunk2}       | ${3}
      ${2}       | ${chunk3Result} | ${3}
    `('renders chunk $chunkIndex', ({ chunkIndex, chunkContent, totalChunks }) => {
      const chunk = findChunks().at(chunkIndex);

      expect(chunk.props('content')).toContain(chunkContent.trim());

      expect(chunk.props()).toMatchObject({
        totalLines: LINES_PER_CHUNK,
        startingFrom: LINES_PER_CHUNK * chunkIndex,
        totalChunks,
      });
    });

    it('emits showBlobInteractionZones on the eventHub when chunk appears', () => {
      findChunks().at(0).vm.$emit('appear');
      expect(eventHub.$emit).toHaveBeenCalledWith('showBlobInteractionZones', path);
    });
  });

  describe('LineHighlighter', () => {
    it('instantiates the lineHighlighter class', () => {
      expect(LineHighlighter).toHaveBeenCalledWith({ scrollBehavior: 'auto' });
    });
  });
});
