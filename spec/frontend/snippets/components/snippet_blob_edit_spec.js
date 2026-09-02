import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import SnippetBlobEditHeader from '~/snippets/components/snippet_blob_edit_header.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { joinPaths } from '~/lib/utils/url_utility';
import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { EditorMarkdownPreviewExtension } from '~/editor/extensions/source_editor_markdown_livepreview_ext';

jest.mock('~/alert');

const TEST_ID = 'blob_local_7';
const TEST_PATH = 'foo/bar/test.md';
const TEST_RAW_PATH = '/gitlab/raw/path/to/blob/7';
const TEST_FULL_PATH = joinPaths(TEST_HOST, TEST_RAW_PATH);
const TEST_CONTENT = 'Lorem ipsum dolar sit amet,\nconsectetur adipiscing elit.';
const TEST_JSON_CONTENT = '{"abc":"lorem ipsum"}';

const TEST_BLOB = {
  id: TEST_ID,
  rawPath: TEST_RAW_PATH,
  path: TEST_PATH,
  content: '',
  isLoaded: false,
};

const TEST_BLOB_LOADED = {
  ...TEST_BLOB,
  content: TEST_CONTENT,
  isLoaded: true,
};

const TEST_MARKDOWN_PREVIEW_PATH = '/snippets/preview_markdown';

describe('Snippet Blob Edit component', () => {
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SnippetBlobEdit, {
      propsData: {
        blob: TEST_BLOB,
        markdownPreviewPath: TEST_MARKDOWN_PREVIEW_PATH,
        ...props,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHeader = () => wrapper.findComponent(SnippetBlobEditHeader);
  const findContent = () => wrapper.findComponent(SourceEditor);
  const getLastUpdatedArgs = () => {
    const event = wrapper.emitted()['blob-updated'];

    return event?.[event.length - 1][0];
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(TEST_FULL_PATH).reply(HTTP_STATUS_OK, TEST_CONTENT);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('with not loaded blob', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows blob header', () => {
      expect(findHeader().props()).toMatchObject({
        value: TEST_BLOB.path,
      });
      expect(findHeader().attributes('id')).toBe(`${TEST_ID}_file_path`);
    });

    it('emits delete when deleted', () => {
      expect(wrapper.emitted().delete).toBeUndefined();

      findHeader().vm.$emit('delete');

      expect(wrapper.emitted().delete).toHaveLength(1);
    });

    it('emits update when path changes', () => {
      const newPath = 'new/path.md';

      findHeader().vm.$emit('input', newPath);

      expect(getLastUpdatedArgs()).toEqual({ path: newPath });
    });

    it('emits update when content is loaded', async () => {
      await waitForPromises();

      expect(getLastUpdatedArgs()).toEqual({ content: TEST_CONTENT });
    });
  });

  describe('with unloaded blob and JSON content', () => {
    beforeEach(() => {
      jest.spyOn(axios, 'get');
      axiosMock.onGet(TEST_FULL_PATH).reply(HTTP_STATUS_OK, TEST_JSON_CONTENT);
      createComponent();
    });

    it('makes an API request for the blob content', () => {
      const expectedConfig = {
        transformResponse: [expect.any(Function)],
        headers: { 'Cache-Control': 'no-cache' },
      };

      expect(axios.get).toHaveBeenCalledWith(TEST_FULL_PATH, expectedConfig);
    });

    // This checks against this issue https://gitlab.com/gitlab-org/gitlab/-/issues/241199
    it('emits raw content', async () => {
      await waitForPromises();

      expect(getLastUpdatedArgs()).toEqual({ content: TEST_JSON_CONTENT });
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      axiosMock.reset();
      axiosMock.onGet(TEST_FULL_PATH).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();
    });

    it('should call alert', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: "Can't fetch content for the blob: Error: Request failed with status code 500",
      });
    });
  });

  describe('with loaded blob', () => {
    beforeEach(() => {
      createComponent({ blob: TEST_BLOB_LOADED });
    });

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('does not make API request', () => {
      expect(axiosMock.history.get).toHaveLength(0);
    });
  });

  describe.each`
    props                                                       | showLoading | showContent
    ${{ blob: TEST_BLOB, canDelete: true, showDelete: true }}   | ${true}     | ${false}
    ${{ blob: TEST_BLOB, canDelete: false, showDelete: false }} | ${true}     | ${false}
    ${{ blob: TEST_BLOB_LOADED }}                               | ${false}    | ${true}
  `('with $props', ({ props, showLoading, showContent }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it('shows blob header', () => {
      const { canDelete = true, showDelete = true } = props;

      expect(findHeader().props()).toMatchObject({
        canDelete,
        showDelete,
      });
    });

    it(`handles loading icon (show=${showLoading})`, () => {
      expect(findLoadingIcon().exists()).toBe(showLoading);
    });

    it(`handles content (show=${showContent})`, () => {
      expect(findContent().exists()).toBe(showContent);

      if (showContent) {
        expect(findContent().props()).toEqual(
          expect.objectContaining({
            value: TEST_BLOB_LOADED.content,
            fileGlobalId: TEST_BLOB_LOADED.id,
            fileName: TEST_BLOB_LOADED.path,
            useDynamicHeight: true,
          }),
        );
      }
    });
  });

  describe('markdown preview', () => {
    const installedExtension = { extensionName: 'EditorMarkdownPreview' };
    const expectedUseArgs = {
      definition: EditorMarkdownPreviewExtension,
      setupOptions: { previewMarkdownPath: TEST_MARKDOWN_PREVIEW_PATH },
    };
    let useSpy;
    let unuseSpy;

    beforeEach(() => {
      useSpy = jest.fn().mockReturnValue(installedExtension);
      unuseSpy = jest.fn();
    });

    const emitEditorReady = () => {
      findContent().vm.$emit(EDITOR_READY_EVENT, {
        detail: { instance: { use: useSpy, unuse: unuseSpy } },
      });
    };

    const renameBlob = (path) => wrapper.setProps({ blob: { ...TEST_BLOB_LOADED, path } });

    describe('with a markdown file', () => {
      beforeEach(() => {
        createComponent({
          blob: { ...TEST_BLOB_LOADED, path: 'README.md' },
        });
      });

      describe('when the editor is ready', () => {
        beforeEach(async () => {
          emitEditorReady();
          await waitForPromises();
        });

        it('installs the markdown extension', () => {
          expect(useSpy).toHaveBeenCalledWith(expectedUseArgs);
        });

        it('uninstalls the extension when renamed to a non-markdown file', async () => {
          await renameBlob('script.rb');
          await waitForPromises();

          expect(unuseSpy).toHaveBeenCalledWith(installedExtension);
        });

        it('does not reinstall the extension when renamed to another markdown file extension', async () => {
          await renameBlob('CHANGELOG.markdown');
          await waitForPromises();

          expect(useSpy).toHaveBeenCalledTimes(1);
          expect(unuseSpy).not.toHaveBeenCalled();
        });
      });

      it('does not install the extension when renamed to a non-markdown file during load', async () => {
        emitEditorReady();
        await renameBlob('script.rb');
        await waitForPromises();

        expect(useSpy).not.toHaveBeenCalled();
      });

      it('ends up with the extension installed when renamed back to a markdown file during load', async () => {
        emitEditorReady();
        await renameBlob('script.rb');
        await renameBlob('README.md');
        await waitForPromises();

        expect(useSpy).toHaveBeenCalledTimes(1);
        expect(useSpy).toHaveBeenLastCalledWith(expectedUseArgs);
        expect(unuseSpy).not.toHaveBeenCalled();
      });

      it('installs the extension only once when a second load races the first one', async () => {
        // Two loads can be in flight at once when the file is renamed across
        // the markdown extension boundary before the first load settles.
        // A rename cannot reproduce this in jsdom (imports resolve immediately),
        // so a second editor-ready event is used to create the same interleaving.
        emitEditorReady();
        emitEditorReady();
        await waitForPromises();

        expect(useSpy).toHaveBeenCalledTimes(1);
      });

      it('installs the extension again after a failed installation when renamed away and back', async () => {
        emitEditorReady();
        useSpy.mockImplementationOnce(() => {
          throw new Error('loading failed');
        });
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: expect.stringContaining('An error occurred while rendering the editor'),
        });

        await renameBlob('script.rb');
        expect(unuseSpy).not.toHaveBeenCalled();

        await renameBlob('README.md');
        await waitForPromises();

        expect(useSpy).toHaveBeenCalledTimes(2);
        expect(useSpy).toHaveBeenLastCalledWith(expectedUseArgs);
      });
    });

    describe('with a non-markdown file', () => {
      beforeEach(() => {
        createComponent({
          blob: { ...TEST_BLOB_LOADED, path: 'script.rb' },
        });
      });

      it('does not install the extension', async () => {
        emitEditorReady();
        await waitForPromises();

        expect(useSpy).not.toHaveBeenCalled();
        expect(unuseSpy).not.toHaveBeenCalled();
      });

      it('installs the extension when renamed to a markdown file', async () => {
        emitEditorReady();
        await waitForPromises();
        await renameBlob('README.md');
        await waitForPromises();

        expect(useSpy).toHaveBeenCalledWith(expectedUseArgs);
      });

      it('installs the extension when renamed to a markdown file before the editor is ready', async () => {
        await renameBlob('README.md');
        await waitForPromises();
        emitEditorReady();
        await waitForPromises();

        expect(useSpy).toHaveBeenCalledWith(expectedUseArgs);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });
  });
});
