import hljs from 'highlight.js/lib/core';
import Vue from 'vue';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  EVENT_LABEL_FALLBACK,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
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

const generateContent = (content, totalLines = 1) => {
  let generatedContent = '';
  for (let i = 0; i < totalLines; i += 1) {
    generatedContent += `Line: ${i + 1} = ${content}\n`;
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
  const content = chunk1 + chunk2;
  const path = 'some/path.js';
  const fileType = 'javascript';
  const blamePath = 'some/blame/path.js';
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

  afterEach(() => wrapper.destroy());

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

    it('highlights the first chunk', () => {
      expect(hljs.highlight).toHaveBeenCalledWith(chunk1.trim(), { language: mappedLanguage });
    });

    describe('auto-detects if a language cannot be loaded', () => {
      beforeEach(() => createComponent({ language: 'some_unknown_language' }));

      it('highlights the content with auto-detection', () => {
        expect(hljs.highlightAuto).toHaveBeenCalledWith(chunk1.trim());
      });
    });
  });

  describe('rendering', () => {
    it('renders the first chunk', async () => {
      const firstChunk = findChunks().at(0);

      expect(firstChunk.props('content')).toContain(chunk1);

      expect(firstChunk.props()).toMatchObject({
        totalLines: 70,
        startingFrom: 0,
      });
    });

    it('renders the second chunk', async () => {
      const secondChunk = findChunks().at(1);

      expect(secondChunk.props('content')).toContain(chunk2.trim());

      expect(secondChunk.props()).toMatchObject({
        totalLines: 70,
        startingFrom: 70,
      });
    });
  });

  it('emits showBlobInteractionZones on the eventHub when chunk appears', () => {
    findChunks().at(0).vm.$emit('appear');
    expect(eventHub.$emit).toBeCalledWith('showBlobInteractionZones', path);
  });

  describe('LineHighlighter', () => {
    it('instantiates the lineHighlighter class', async () => {
      expect(LineHighlighter).toHaveBeenCalledWith({ scrollBehavior: 'auto' });
    });
  });
});
