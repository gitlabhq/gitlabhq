import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import BlobEdit from '~/repository/components/blob_edit.vue';
import { loadViewer, viewerProps } from '~/repository/components/blob_viewers';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';
import EmptyViewer from '~/repository/components/blob_viewers/empty_viewer.vue';
import TextViewer from '~/repository/components/blob_viewers/text_viewer.vue';
import blobInfoQuery from '~/repository/queries/blob_info.query.graphql';

jest.mock('~/repository/components/blob_viewers');

let wrapper;
let mockResolver;

const simpleMockData = {
  name: 'some_file.js',
  size: 123,
  rawSize: 123,
  rawTextBlob: 'raw content',
  type: 'text',
  fileType: 'text',
  tooLarge: false,
  path: 'some_file.js',
  webPath: 'some_file.js',
  editBlobPath: 'some_file.js/edit',
  ideEditPath: 'some_file.js/ide/edit',
  storedExternally: false,
  rawPath: 'some_file.js',
  externalStorageUrl: 'some_file.js',
  replacePath: 'some_file.js/replace',
  deletePath: 'some_file.js/delete',
  canLock: true,
  isLocked: false,
  lockLink: 'some_file.js/lock',
  forkPath: 'some_file.js/fork',
  simpleViewer: {
    fileType: 'text',
    tooLarge: false,
    type: 'simple',
    renderError: null,
  },
  richViewer: null,
};
const richMockData = {
  ...simpleMockData,
  richViewer: {
    fileType: 'markup',
    tooLarge: false,
    type: 'rich',
    renderError: null,
  },
};

const projectMockData = {
  userPermissions: {
    pushCode: true,
  },
  repository: {
    empty: false,
  },
};

const localVue = createLocalVue();
const mockAxios = new MockAdapter(axios);

const createComponentWithApollo = (mockData = {}, inject = {}) => {
  localVue.use(VueApollo);

  const defaultPushCode = projectMockData.userPermissions.pushCode;
  const defaultEmptyRepo = projectMockData.repository.empty;
  const { blobs, emptyRepo = defaultEmptyRepo, canPushCode = defaultPushCode } = mockData;

  mockResolver = jest.fn().mockResolvedValue({
    data: {
      project: {
        userPermissions: { pushCode: canPushCode },
        repository: {
          empty: emptyRepo,
          blobs: {
            nodes: [blobs],
          },
        },
      },
    },
  });

  const fakeApollo = createMockApollo([[blobInfoQuery, mockResolver]]);

  wrapper = shallowMount(BlobContentViewer, {
    localVue,
    apolloProvider: fakeApollo,
    propsData: {
      path: 'some_file.js',
      projectPath: 'some/path',
    },
    mixins: [
      {
        data: () => ({ ref: 'default-ref' }),
      },
    ],
    provide: {
      ...inject,
    },
  });
};

const createFactory = (mountFn) => (
  { props = {}, mockData = {}, stubs = {} } = {},
  loading = false,
) => {
  wrapper = mountFn(BlobContentViewer, {
    propsData: {
      path: 'some_file.js',
      projectPath: 'some/path',
      ...props,
    },
    mocks: {
      $apollo: {
        queries: {
          project: {
            loading,
            refetch: jest.fn(),
          },
        },
      },
    },
    stubs,
  });

  wrapper.setData(mockData);
};

const factory = createFactory(shallowMount);
const fullFactory = createFactory(mount);

describe('Blob content viewer component', () => {
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBlobHeader = () => wrapper.findComponent(BlobHeader);
  const findBlobEdit = () => wrapper.findComponent(BlobEdit);
  const findBlobContent = () => wrapper.findComponent(BlobContent);
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a GlLoadingIcon component', () => {
    factory({ mockData: { blobInfo: simpleMockData } }, true);

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('simple viewer', () => {
    beforeEach(() => {
      factory({ mockData: { blobInfo: simpleMockData } });
    });

    it('renders a BlobHeader component', () => {
      expect(findBlobHeader().props('activeViewerType')).toEqual('simple');
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(true);
      expect(findBlobHeader().props('blob')).toEqual(simpleMockData);
    });

    it('renders a BlobContent component', () => {
      expect(findBlobContent().props('loading')).toEqual(false);
      expect(findBlobContent().props('content')).toEqual('raw content');
      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'text',
        tooLarge: false,
        type: 'simple',
        renderError: null,
      });
    });
  });

  describe('rich viewer', () => {
    beforeEach(() => {
      factory({
        mockData: { blobInfo: richMockData, activeViewerType: 'rich' },
      });
    });

    it('renders a BlobHeader component', () => {
      expect(findBlobHeader().props('activeViewerType')).toEqual('rich');
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(false);
      expect(findBlobHeader().props('blob')).toEqual(richMockData);
    });

    it('renders a BlobContent component', () => {
      expect(findBlobContent().props('loading')).toEqual(false);
      expect(findBlobContent().props('content')).toEqual('raw content');
      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'markup',
        tooLarge: false,
        type: 'rich',
        renderError: null,
      });
    });

    it('updates viewer type when viewer changed is clicked', async () => {
      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: 'rich',
        }),
      );
      expect(findBlobHeader().props('activeViewerType')).toEqual('rich');

      findBlobHeader().vm.$emit('viewer-changed', 'simple');
      await nextTick();

      expect(findBlobHeader().props('activeViewerType')).toEqual('simple');
      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: 'simple',
        }),
      );
    });
  });

  describe('legacy viewers', () => {
    it('does not load a legacy viewer when a rich viewer is not available', async () => {
      createComponentWithApollo({ blobs: simpleMockData });
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(0);
    });

    it('loads a legacy viewer when a rich viewer is available', async () => {
      createComponentWithApollo({ blobs: richMockData });
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(1);
    });
  });

  describe('Blob viewer', () => {
    afterEach(() => {
      loadViewer.mockRestore();
      viewerProps.mockRestore();
    });

    it('does not render a BlobContent component if a Blob viewer is available', () => {
      loadViewer.mockReturnValueOnce(() => true);
      factory({ mockData: { blobInfo: richMockData } });

      expect(findBlobContent().exists()).toBe(false);
    });

    it.each`
      viewer        | loadViewerReturnValue | viewerPropsReturnValue
      ${'empty'}    | ${EmptyViewer}        | ${{}}
      ${'download'} | ${DownloadViewer}     | ${{ filePath: '/some/file/path', fileName: 'test.js', fileSize: 100 }}
      ${'text'}     | ${TextViewer}         | ${{ content: 'test', fileName: 'test.js', readOnly: true }}
    `(
      'renders viewer component for $viewer files',
      async ({ viewer, loadViewerReturnValue, viewerPropsReturnValue }) => {
        loadViewer.mockReturnValue(loadViewerReturnValue);
        viewerProps.mockReturnValue(viewerPropsReturnValue);

        factory({
          mockData: {
            blobInfo: {
              ...simpleMockData,
              fileType: null,
              simpleViewer: {
                ...simpleMockData.simpleViewer,
                fileType: viewer,
              },
            },
          },
        });

        await nextTick();

        expect(loadViewer).toHaveBeenCalledWith(viewer);
        expect(wrapper.findComponent(loadViewerReturnValue).exists()).toBe(true);
      },
    );
  });

  describe('BlobHeader action slot', () => {
    const { ideEditPath, editBlobPath } = simpleMockData;

    it('renders BlobHeaderEdit buttons in simple viewer', async () => {
      fullFactory({
        mockData: { blobInfo: simpleMockData },
        stubs: {
          BlobContent: true,
          BlobReplace: true,
        },
      });

      await nextTick();

      expect(findBlobEdit().props()).toMatchObject({
        editPath: editBlobPath,
        webIdePath: ideEditPath,
      });
    });

    it('renders BlobHeaderEdit button in rich viewer', async () => {
      fullFactory({
        mockData: { blobInfo: richMockData },
        stubs: {
          BlobContent: true,
          BlobReplace: true,
        },
      });

      await nextTick();

      expect(findBlobEdit().props()).toMatchObject({
        editPath: editBlobPath,
        webIdePath: ideEditPath,
      });
    });

    it('does not render BlobHeaderEdit button when viewing a binary file', async () => {
      fullFactory({
        mockData: { blobInfo: richMockData, isBinary: true },
        stubs: {
          BlobContent: true,
          BlobReplace: true,
        },
      });

      await nextTick();

      expect(findBlobEdit().exists()).toBe(false);
    });

    describe('BlobButtonGroup', () => {
      const { name, path, replacePath, webPath } = simpleMockData;
      const {
        userPermissions: { pushCode },
        repository: { empty },
      } = projectMockData;

      it('renders component', async () => {
        window.gon.current_user_id = 1;

        fullFactory({
          mockData: {
            blobInfo: simpleMockData,
            project: { userPermissions: { pushCode }, repository: { empty } },
          },
          stubs: {
            BlobContent: true,
            BlobButtonGroup: true,
          },
        });

        await nextTick();

        expect(findBlobButtonGroup().props()).toMatchObject({
          name,
          path,
          replacePath,
          deletePath: webPath,
          canPushCode: pushCode,
          emptyRepo: empty,
        });
      });

      it('does not render if not logged in', async () => {
        window.gon.current_user_id = null;

        fullFactory({
          mockData: { blobInfo: simpleMockData },
          stubs: {
            BlobContent: true,
            BlobReplace: true,
          },
        });

        await nextTick();

        expect(findBlobButtonGroup().exists()).toBe(false);
      });
    });
  });

  describe('blob info query', () => {
    it('is called with originalBranch value if the prop has a value', async () => {
      const inject = { originalBranch: 'some-branch' };
      createComponentWithApollo({ blobs: simpleMockData }, inject);

      await waitForPromises();

      expect(mockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'some-branch',
        }),
      );
    });

    it('is called with ref value if the originalBranch prop has no value', async () => {
      const inject = { originalBranch: null };
      createComponentWithApollo({ blobs: simpleMockData }, inject);

      await waitForPromises();

      expect(mockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'default-ref',
        }),
      );
    });
  });
});
