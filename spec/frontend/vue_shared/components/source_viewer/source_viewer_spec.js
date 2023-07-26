import hljs from 'highlight.js/lib/core';
import Vue from 'vue';
import VueRouter from 'vue-router';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import { registerPlugins } from '~/vue_shared/components/source_viewer/plugins/index';
import Chunk from '~/vue_shared/components/source_viewer/components/chunk.vue';
import {
  EVENT_ACTION,
  EVENT_LABEL_VIEWER,
  EVENT_LABEL_FALLBACK,
  ROUGE_TO_HLJS_LANGUAGE_MAP,
  LINES_PER_CHUNK,
  LEGACY_FALLBACKS,
  CODEOWNERS_FILE_NAME,
  CODEOWNERS_LANGUAGE,
  SVELTE_LANGUAGE,
} from '~/vue_shared/components/source_viewer/constants';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import LineHighlighter from '~/blob/line_highlighter';
import eventHub from '~/notes/event_hub';
import Tracking from '~/tracking';

jest.mock('~/blob/line_highlighter');
jest.mock('highlight.js/lib/core');
jest.mock('~/vue_shared/components/source_viewer/plugins/index');
Vue.use(VueRouter);
const router = new VueRouter();
const mockAxios = new MockAdapter(axios);

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

  describe('Displaying LFS blob', () => {
    const rawPath = '/org/project/-/raw/file.xml';
    const externalStorageUrl = 'http://127.0.0.1:9000/lfs-objects/91/12/1341234';
    const rawTextBlob = 'This is the external content';
    const blob = {
      storedExternally: true,
      externalStorage: 'lfs',
      simpleViewer: { fileType: 'text' },
      rawPath,
    };

    afterEach(() => {
      mockAxios.reset();
    });

    it('Uses externalStorageUrl to fetch content if present', async () => {
      mockAxios.onGet(externalStorageUrl).replyOnce(HTTP_STATUS_OK, rawTextBlob);

      await createComponent({ ...blob, externalStorageUrl });

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toBe(externalStorageUrl);
      expect(wrapper.vm.$data.content).toBe(rawTextBlob);
    });

    it('Falls back to rawPath to fetch content', async () => {
      mockAxios.onGet(rawPath).replyOnce(HTTP_STATUS_OK, rawTextBlob);

      await createComponent(blob);

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toBe(rawPath);
      expect(wrapper.vm.$data.content).toBe(rawTextBlob);
    });
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

    describe('sub-languages', () => {
      const languageDefinition = {
        subLanguage: 'xml',
        contains: [{ subLanguage: 'javascript' }, { subLanguage: 'typescript' }],
      };

      beforeEach(async () => {
        jest.spyOn(hljs, 'getLanguage').mockReturnValue(languageDefinition);
        createComponent();
        await waitForPromises();
      });

      it('registers the primary sub-language', () => {
        expect(hljs.registerLanguage).toHaveBeenCalledWith(
          languageDefinition.subLanguage,
          expect.any(Function),
        );
      });

      it.each(languageDefinition.contains)(
        'registers the rest of the sub-languages',
        ({ subLanguage }) => {
          expect(hljs.registerLanguage).toHaveBeenCalledWith(subLanguage, expect.any(Function));
        },
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

    it('registers codeowners language definition if file name is CODEOWNERS', async () => {
      await createComponent({ name: CODEOWNERS_FILE_NAME });
      const languageDefinition = await import(
        '~/vue_shared/components/source_viewer/languages/codeowners'
      );

      expect(hljs.registerLanguage).toHaveBeenCalledWith(
        CODEOWNERS_LANGUAGE,
        languageDefinition.default,
      );
    });

    it('registers svelte language definition if file name ends with .svelte', async () => {
      await createComponent({ name: `component.${SVELTE_LANGUAGE}` });
      const languageDefinition = await import(
        '~/vue_shared/components/source_viewer/languages/svelte'
      );

      expect(hljs.registerLanguage).toHaveBeenCalledWith(
        SVELTE_LANGUAGE,
        languageDefinition.default,
      );
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
