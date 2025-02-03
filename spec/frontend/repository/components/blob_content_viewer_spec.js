import { GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import ForkSuggestion from '~/repository/components/fork_suggestion.vue';
import { loadViewer } from '~/repository/components/blob_viewers';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';
import EmptyViewer from '~/repository/components/blob_viewers/empty_viewer.vue';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer.vue';
import TooLargeViewer from '~/repository/components/blob_viewers/too_large_viewer.vue';
import LfsViewer from '~/repository/components/blob_viewers/lfs_viewer.vue';
import blobInfoQuery from 'shared_queries/repository/blob_info.query.graphql';
import projectInfoQuery from '~/repository/queries/project_info.query.graphql';
import highlightMixin from '~/repository/mixins/highlight_mixin';
import getRefMixin from '~/repository/mixins/get_ref';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CodeIntelligence from '~/code_navigation/components/app.vue';
import * as urlUtility from '~/lib/utils/url_utility';
import { isLoggedIn, handleLocationHash } from '~/lib/utils/common_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import LineHighlighter from '~/blob/line_highlighter';
import { LEGACY_FILE_TYPES } from '~/repository/constants';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import {
  simpleViewerMock,
  richViewerMock,
  projectMock,
  userPermissionsMock,
  propsMock,
  axiosMockResponse,
  FILE_SIZE_3MB,
} from '../mock_data';

jest.mock('~/repository/components/blob_viewers');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/blob/line_highlighter');
jest.mock('~/alert');

let wrapper;
let blobInfoMockResolver;
let projectInfoMockResolver;

Vue.use(Vuex);

const mockAxios = new MockAdapter(axios);

const createMockStore = () =>
  new Vuex.Store({ actions: { fetchData: jest.fn, setInitialData: jest.fn() } });

const mockRouterPush = jest.fn();
const mockRouter = {
  push: mockRouterPush,
};
const highlightWorker = { postMessage: jest.fn() };

const legacyViewerUrl = '/some_file.js?format=json&viewer=simple';

const createComponent = async (mockData = {}, mountFn = shallowMount, mockRoute = {}) => {
  Vue.use(VueApollo);

  const {
    blob = simpleViewerMock,
    empty = projectMock.repository.empty,
    pushCode = userPermissionsMock.pushCode,
    forkProject = userPermissionsMock.forkProject,
    downloadCode = userPermissionsMock.downloadCode,
    createMergeRequestIn = userPermissionsMock.createMergeRequestIn,
    isBinary,
    inject = { highlightWorker },
  } = mockData;

  const blobInfo = {
    ...projectMock,
    repository: {
      __typename: 'Repository',
      empty,
      blobs: {
        __typename: 'RepositoryBlobConnection',
        nodes: [blob],
      },
    },
  };

  const projectInfo = {
    ...projectMock,
    userPermissions: {
      pushCode,
      forkProject,
      downloadCode,
      createMergeRequestIn,
    },
  };

  projectInfoMockResolver = jest.fn().mockResolvedValue({
    data: { project: projectInfo },
  });

  blobInfoMockResolver = jest.fn().mockResolvedValue({
    data: { isBinary, project: blobInfo },
  });

  const fakeApollo = createMockApollo([
    [blobInfoQuery, blobInfoMockResolver],
    [projectInfoQuery, projectInfoMockResolver],
  ]);

  wrapper = extendedWrapper(
    mountFn(BlobContentViewer, {
      store: createMockStore(),
      apolloProvider: fakeApollo,
      propsData: propsMock,
      mixins: [getRefMixin, highlightMixin, glFeatureFlagMixin()],
      mocks: {
        $route: mockRoute,
        $router: mockRouter,
      },
      provide: {
        targetBranch: 'test',
        originalBranch: 'default-ref',
        glFeatures: { inlineBlame: true },
        ...inject,
      },
    }),
  );

  await waitForPromises();
};

const execImmediately = (callback) => {
  callback();
};

describe('Blob content viewer component', () => {
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBlobHeader = () => wrapper.findComponent(BlobHeader);
  const findBlobContent = () => wrapper.findComponent(BlobContent);
  const findBlobButtonGroup = () => wrapper.findComponent(BlobButtonGroup);
  const findForkSuggestion = () => wrapper.findComponent(ForkSuggestion);
  const findCodeIntelligence = () => wrapper.findComponent(CodeIntelligence);
  const findSourceViewer = () => wrapper.findComponent(SourceViewer);

  beforeEach(() => {
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);
    isLoggedIn.mockReturnValue(true);
  });

  afterEach(() => {
    mockAxios.reset();
  });

  it('renders a GlLoadingIcon component', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  describe('simple viewer', () => {
    it('renders a BlobHeader component', async () => {
      await createComponent();

      expect(findBlobHeader().props('activeViewerType')).toEqual(SIMPLE_BLOB_VIEWER);
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(false);
      expect(findBlobHeader().props('blob')).toEqual(simpleViewerMock);
      expect(findBlobHeader().props('showForkSuggestion')).toEqual(false);
      expect(findBlobHeader().props('showBlameToggle')).toEqual(true);
      expect(findBlobHeader().props('projectPath')).toEqual(propsMock.projectPath);
      expect(findBlobHeader().props('projectId')).toEqual(projectMock.id);
      expect(mockRouterPush).not.toHaveBeenCalled();
    });

    describe('blame toggle', () => {
      const triggerBlame = async () => {
        findBlobHeader().vm.$emit('blame');
        await nextTick();
      };

      it('renders a blame toggle', async () => {
        await createComponent({ blob: simpleViewerMock });

        expect(findBlobHeader().props('showBlameToggle')).toEqual(true);
      });

      it('adds blame param to the URL and passes `showBlame` to the SourceViewer', async () => {
        loadViewer.mockReturnValueOnce(SourceViewer);
        await createComponent({ blob: simpleViewerMock });

        await triggerBlame();

        expect(mockRouterPush).toHaveBeenCalledWith({ query: { blame: '1' } });
        expect(findSourceViewer().props('showBlame')).toBe(true);

        await triggerBlame();

        expect(mockRouterPush).toHaveBeenCalledWith({ query: { blame: '0' } });
        expect(findSourceViewer().props('showBlame')).toBe(false);
      });

      describe('when viewing rich content', () => {
        it('always shows the blame when clicking on the blame button', async () => {
          loadViewer.mockReturnValueOnce(SourceViewer);
          const query = { plain: '0', blame: '1' };
          await createComponent({ blob: simpleViewerMock }, shallowMount, { query });
          await triggerBlame();

          expect(findSourceViewer().props('showBlame')).toBe(true);
        });
      });
    });

    it('creates an alert when the BlobHeader component emits an error', async () => {
      await createComponent();

      findBlobHeader().vm.$emit('error');

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while loading the file. Please try again.',
      });
    });

    it('copies blob text to clipboard', async () => {
      jest.spyOn(navigator.clipboard, 'writeText');
      await createComponent();

      findBlobHeader().vm.$emit('copy');
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(simpleViewerMock.rawTextBlob);
    });

    it('renders a BlobContent component', async () => {
      await createComponent();

      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'text',
        tooLarge: false,
        type: SIMPLE_BLOB_VIEWER,
        renderError: null,
      });
    });

    describe('legacy viewers', () => {
      const fileType = 'text';

      it('loads a legacy viewer when the source viewer emits an error', async () => {
        loadViewer.mockReturnValueOnce(SourceViewer);
        await createComponent();
        findSourceViewer().vm.$emit('error');
        await waitForPromises();

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].url).toBe(legacyViewerUrl);
        expect(findBlobHeader().props('showBlameToggle')).toEqual(true);
      });

      it('loads a legacy viewer when a viewer component is not available', async () => {
        await createComponent({ blob: { ...simpleViewerMock, fileType: 'unknown' } });

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].url).toBe(legacyViewerUrl);
      });

      it.each(LEGACY_FILE_TYPES)(
        'loads the legacy viewer when a file type is identified as legacy',
        async (type) => {
          await createComponent({ blob: { ...simpleViewerMock, fileType: type, webPath: type } });
          expect(mockAxios.history.get[0].url).toBe(`/${type}?format=json&viewer=simple`);
        },
      );

      it('loads the LineHighlighter', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...simpleViewerMock, fileType } });
        expect(LineHighlighter).toHaveBeenCalled();
      });

      it('does not load the LineHighlighter for RichViewers', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...richViewerMock, fileType } });
        expect(LineHighlighter).not.toHaveBeenCalled();
      });

      it('scrolls to the hash', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...simpleViewerMock, fileType } });
        expect(handleLocationHash).toHaveBeenCalled();
      });
    });
  });

  describe('rich viewer', () => {
    it('renders a BlobHeader component', async () => {
      await createComponent({ blob: richViewerMock });

      expect(findBlobHeader().props('activeViewerType')).toEqual(RICH_BLOB_VIEWER);
      expect(findBlobHeader().props('hasRenderError')).toEqual(false);
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(false);
      expect(findBlobHeader().props('blob')).toEqual(richViewerMock);
      expect(mockRouterPush).not.toHaveBeenCalled();
    });

    it('renders a BlobContent component', async () => {
      await createComponent({ blob: richViewerMock });

      expect(findBlobContent().props('isRawContent')).toBe(true);
      expect(findBlobContent().props('activeViewer')).toEqual({
        fileType: 'markup',
        tooLarge: false,
        type: RICH_BLOB_VIEWER,
        renderError: null,
      });
    });

    it('changes to simple viewer when URL has code line hash', async () => {
      jest.spyOn(urlUtility, 'getLocationHash').mockReturnValueOnce('L5');

      await createComponent({ blob: richViewerMock });

      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: SIMPLE_BLOB_VIEWER,
        }),
      );
      expect(findBlobHeader().props('activeViewerType')).toEqual(SIMPLE_BLOB_VIEWER);
    });

    it('updates viewer type when viewer changed is clicked', async () => {
      await createComponent({ blob: richViewerMock }, shallowMount, { path: '/mock_path' });

      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: RICH_BLOB_VIEWER,
        }),
      );
      expect(findBlobHeader().props('activeViewerType')).toEqual(RICH_BLOB_VIEWER);

      findBlobHeader().vm.$emit('viewer-changed', SIMPLE_BLOB_VIEWER);
      await nextTick();

      expect(findBlobHeader().props('activeViewerType')).toEqual(SIMPLE_BLOB_VIEWER);
      expect(findBlobContent().props('activeViewer')).toEqual(
        expect.objectContaining({
          type: SIMPLE_BLOB_VIEWER,
        }),
      );
      expect(mockRouterPush).toHaveBeenCalledWith({
        path: '/mock_path',
        query: {
          plain: '1',
        },
      });
    });
  });

  describe('legacy viewers', () => {
    it('loads a legacy viewer when a viewer component is not available', async () => {
      await createComponent({ blob: { ...richViewerMock, fileType: 'unknown' } });

      expect(mockAxios.history.get).toHaveLength(1);
      expect(mockAxios.history.get[0].url).toEqual('/some_file.js?format=json&viewer=rich');
    });
  });

  describe('Blob viewer', () => {
    afterEach(() => {
      loadViewer.mockRestore();
    });

    it('renders a CodeIntelligence component with the correct props', async () => {
      loadViewer.mockReturnValue(SourceViewer);

      await createComponent();

      expect(findCodeIntelligence().props()).toMatchObject({
        codeNavigationPath: simpleViewerMock.codeNavigationPath,
        blobPath: simpleViewerMock.path,
        pathPrefix: simpleViewerMock.projectBlobPathRoot,
        wrapTextNodes: true,
      });
    });

    it('does not load a CodeIntelligence component when no viewers are loaded', async () => {
      const url = '/some_file.js?format=json&viewer=rich';
      mockAxios.onGet(url).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      await createComponent({ blob: { ...richViewerMock, fileType: 'unknown' } });

      expect(findCodeIntelligence().exists()).toBe(false);
    });

    it('does not render a BlobContent component if a Blob viewer is available', async () => {
      loadViewer.mockReturnValue(() => true);
      await createComponent({ blob: richViewerMock });
      await waitForPromises();
      expect(findBlobContent().exists()).toBe(false);
    });

    it.each([EmptyViewer, DownloadViewer, SourceViewer, LfsViewer, TooLargeViewer])(
      'renders viewer component for %s files',
      async (loadViewerReturnValue) => {
        loadViewer.mockReturnValue(loadViewerReturnValue);
        await createComponent();

        expect(wrapper.findComponent(loadViewerReturnValue).exists()).toBe(true);
      },
    );

    it.each`
      language  | size             | tooLarge | renderError    | expectedTooLarge
      ${'ruby'} | ${100}           | ${false} | ${null}        | ${false}
      ${'ruby'} | ${FILE_SIZE_3MB} | ${false} | ${null}        | ${true}
      ${'nyan'} | ${null}          | ${true}  | ${null}        | ${true}
      ${'nyan'} | ${null}          | ${false} | ${'collapsed'} | ${true}
    `(
      'correctly handles file size limits when language=$language, size=$size, tooLarge=$tooLarge, renderError=$renderError',
      async ({ language, size, tooLarge, renderError, expectedTooLarge }) => {
        await createComponent({
          blob: {
            ...simpleViewerMock,
            language,
            size,
            simpleViewer: {
              ...simpleViewerMock.simpleViewer,
              tooLarge,
              renderError,
            },
          },
        });

        await waitForPromises();
        expect(loadViewer).toHaveBeenCalledWith('text', false, expectedTooLarge);
      },
    );
  });

  describe('BlobHeader action slot', () => {
    describe('blob header binary file', () => {
      it('passes the correct isBinary value when viewing a binary file', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, axiosMockResponse);
        await createComponent();

        expect(findBlobHeader().props('isBinary')).toBe(true);
      });

      it('passes the correct header props when viewing a non-text file', async () => {
        await createComponent(
          {
            blob: {
              ...simpleViewerMock,
              simpleViewer: {
                ...simpleViewerMock.simpleViewer,
                fileType: 'image',
              },
            },
            isBinary: true,
          },
          mount,
        );

        expect(findBlobHeader().props('hideViewerSwitcher')).toBe(true);
        expect(findBlobHeader().props('isBinary')).toBe(true);
      });
    });

    describe('BlobButtonGroup', () => {
      const { name, path, replacePath, webPath } = simpleViewerMock;
      const {
        userPermissions: { pushCode, downloadCode },
        repository: { empty },
      } = projectMock;

      it('renders component', async () => {
        window.gon.current_user_id = 'gid://gitlab/User/1';
        window.gon.current_username = 'root';

        await createComponent({ pushCode, downloadCode, empty }, mount);

        expect(findBlobButtonGroup().props()).toMatchObject({
          name,
          path,
          replacePath,
          deletePath: webPath,
          canPushCode: pushCode,
          canLock: true,
          isLocked: false,
          emptyRepo: empty,
        });
      });

      it('does not render if not logged in', async () => {
        isLoggedIn.mockReturnValueOnce(false);

        await createComponent();

        expect(findBlobButtonGroup().exists()).toBe(false);
      });
    });
  });

  describe('blob info query', () => {
    it('calls blob info query with shouldFetchRawText: true', async () => {
      await createComponent();

      expect(blobInfoMockResolver).toHaveBeenCalledWith(
        expect.objectContaining({ shouldFetchRawText: true }),
      );
    });

    it('is called with originalBranch value if the prop has a value', async () => {
      await createComponent({ inject: { originalBranch: 'some-branch', highlightWorker } });

      expect(blobInfoMockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'some-branch',
        }),
      );
    });

    it('is called with ref value if the originalBranch prop has no value', async () => {
      await createComponent();

      expect(blobInfoMockResolver).toHaveBeenCalledWith(
        expect.objectContaining({
          ref: 'default-ref',
        }),
      );
    });
  });

  describe('edit blob', () => {
    beforeEach(() => createComponent({}, mount));

    it('simple edit redirects to the simple editor', () => {
      findBlobHeader().vm.$emit('edit', 'simple');
      expect(urlUtility.visitUrl).toHaveBeenCalledWith(simpleViewerMock.editBlobPath);
    });

    it('IDE edit redirects to the IDE editor', () => {
      findBlobHeader().vm.$emit('edit', 'ide');
      expect(urlUtility.visitUrl).toHaveBeenCalledWith(simpleViewerMock.ideEditPath);
    });

    it.each`
      loggedIn | canModifyBlob | isUsingLfs | createMergeRequestIn | forkProject | showSingleFileEditorForkSuggestion
      ${true}  | ${true}       | ${false}   | ${true}              | ${true}     | ${false}
      ${true}  | ${false}      | ${false}   | ${true}              | ${true}     | ${true}
      ${false} | ${false}      | ${false}   | ${true}              | ${true}     | ${false}
      ${true}  | ${false}      | ${false}   | ${false}             | ${true}     | ${false}
      ${true}  | ${false}      | ${false}   | ${true}              | ${false}    | ${false}
      ${true}  | ${false}      | ${true}    | ${true}              | ${true}     | ${false}
    `(
      'shows/hides a fork suggestion according to a set of conditions',
      async ({
        loggedIn,
        canModifyBlob,
        isUsingLfs,
        createMergeRequestIn,
        forkProject,
        showSingleFileEditorForkSuggestion,
      }) => {
        isLoggedIn.mockReturnValueOnce(loggedIn);
        await createComponent(
          {
            blob: { ...simpleViewerMock, canModifyBlob, storedExternally: isUsingLfs },
            createMergeRequestIn,
            forkProject,
          },
          mount,
        );

        findBlobHeader().vm.$emit('edit', 'simple');
        await nextTick();

        expect(findForkSuggestion().exists()).toBe(showSingleFileEditorForkSuggestion);
      },
    );

    it.each`
      loggedIn | canModifyBlobWithWebIde | isUsingLfs | createMergeRequestIn | forkProject | showWebIdeForkSuggestion
      ${true}  | ${true}                 | ${false}   | ${true}              | ${true}     | ${false}
      ${true}  | ${false}                | ${false}   | ${true}              | ${true}     | ${true}
      ${false} | ${false}                | ${false}   | ${true}              | ${true}     | ${false}
      ${true}  | ${false}                | ${false}   | ${false}             | ${true}     | ${false}
      ${true}  | ${false}                | ${false}   | ${true}              | ${false}    | ${false}
      ${true}  | ${false}                | ${true}    | ${true}              | ${true}     | ${false}
    `(
      'shows/hides a fork suggestion for WebIDE according to a set of conditions',
      async ({
        loggedIn,
        canModifyBlobWithWebIde,
        isUsingLfs,
        createMergeRequestIn,
        forkProject,
        showWebIdeForkSuggestion,
      }) => {
        isLoggedIn.mockReturnValueOnce(loggedIn);
        await createComponent(
          {
            blob: { ...simpleViewerMock, canModifyBlobWithWebIde, storedExternally: isUsingLfs },
            createMergeRequestIn,
            forkProject,
          },
          mount,
        );

        findBlobHeader().vm.$emit('edit', 'ide');
        await nextTick();

        expect(findForkSuggestion().exists()).toBe(showWebIdeForkSuggestion);
      },
    );
  });

  describe('active viewer based on plain attribute', () => {
    it.each`
      hasRichViewer | plain  | activeViewerType
      ${true}       | ${'0'} | ${RICH_BLOB_VIEWER}
      ${true}       | ${'1'} | ${SIMPLE_BLOB_VIEWER}
      ${false}      | ${'0'} | ${SIMPLE_BLOB_VIEWER}
      ${false}      | ${'1'} | ${SIMPLE_BLOB_VIEWER}
    `(
      'activeViewerType is `$activeViewerType` when hasRichViewer is $hasRichViewer and plain is set to $plain',
      async ({ hasRichViewer, plain, activeViewerType }) => {
        await createComponent(
          { blob: hasRichViewer ? richViewerMock : simpleViewerMock },
          shallowMount,
          { query: { plain } },
        );

        await nextTick();

        expect(findBlobContent().props('activeViewer')).toEqual(
          expect.objectContaining({
            type: activeViewerType,
          }),
        );
        expect(findBlobHeader().props('activeViewerType')).toEqual(activeViewerType);
      },
    );
  });
});
