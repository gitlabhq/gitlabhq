import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

jest.mock('~/flash');

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

describe('Snippet Blob Edit component', () => {
  let wrapper;
  let axiosMock;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SnippetBlobEdit, {
      propsData: {
        blob: TEST_BLOB,
        ...props,
      },
    });
  };

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findHeader = () => wrapper.find(BlobHeaderEdit);
  const findContent = () => wrapper.find(SourceEditor);
  const getLastUpdatedArgs = () => {
    const event = wrapper.emitted()['blob-updated'];

    return event?.[event.length - 1][0];
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(TEST_FULL_PATH).reply(200, TEST_CONTENT);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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
      axiosMock.onGet(TEST_FULL_PATH).reply(200, TEST_JSON_CONTENT);
      createComponent();
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
      axiosMock.onGet(TEST_FULL_PATH).replyOnce(500);
      createComponent();
    });

    it('should call flash', async () => {
      await waitForPromises();

      expect(createFlash).toHaveBeenCalledWith({
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
          }),
        );
      }
    });
  });
});
