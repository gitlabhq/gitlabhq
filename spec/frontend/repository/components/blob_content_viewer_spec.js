import { GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobButtonGroup from '~/repository/components/blob_button_group.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import ForkSuggestion from '~/repository/components/fork_suggestion.vue';
import { loadViewer } from '~/repository/components/blob_viewers';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';
import EmptyViewer from '~/repository/components/blob_viewers/empty_viewer.vue';
import SourceViewer from '~/vue_shared/components/source_viewer/source_viewer_deprecated.vue';
import blobInfoQuery from 'shared_queries/repository/blob_info.query.graphql';
import projectInfoQuery from '~/repository/queries/project_info.query.graphql';
import userInfoQuery from '~/repository/queries/user_info.query.graphql';
import applicationInfoQuery from '~/repository/queries/application_info.query.graphql';
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
  userInfoMock,
  applicationInfoMock,
  userPermissionsMock,
  propsMock,
  refMock,
} from '../mock_data';

jest.mock('~/repository/components/blob_viewers');
jest.mock('~/lib/utils/url_utility');
jest.mock('~/lib/utils/common_utils');
jest.mock('~/blob/line_highlighter');

let wrapper;
let blobInfoMockResolver;
let userInfoMockResolver;
let projectInfoMockResolver;
let applicationInfoMockResolver;

const mockAxios = new MockAdapter(axios);

const createMockStore = () =>
  new Vuex.Store({ actions: { fetchData: jest.fn, setInitialData: jest.fn() } });

const mockRouterPush = jest.fn();
const mockRouter = {
  push: mockRouterPush,
};

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
    inject = {},
    highlightJs = true,
  } = mockData;

  const blobInfo = {
    ...projectMock,
    repository: {
      empty,
      blobs: { nodes: [blob] },
    },
  };

  const projectInfo = {
    __typename: 'Project',
    id: '123',
    userPermissions: {
      pushCode,
      forkProject,
      downloadCode,
      createMergeRequestIn,
    },
    pathLocks: {
      nodes: [
        {
          id: 'test',
          path: 'locked_file.js',
          user: { id: '123', username: 'root' },
        },
      ],
    },
  };

  projectInfoMockResolver = jest.fn().mockResolvedValue({
    data: { project: projectInfo },
  });

  blobInfoMockResolver = jest.fn().mockResolvedValue({
    data: { isBinary, project: blobInfo },
  });

  userInfoMockResolver = jest.fn().mockResolvedValue({
    data: { ...userInfoMock },
  });

  applicationInfoMockResolver = jest.fn().mockResolvedValue({
    data: { ...applicationInfoMock },
  });

  const fakeApollo = createMockApollo([
    [blobInfoQuery, blobInfoMockResolver],
    [userInfoQuery, userInfoMockResolver],
    [projectInfoQuery, projectInfoMockResolver],
    [applicationInfoQuery, applicationInfoMockResolver],
  ]);

  wrapper = extendedWrapper(
    mountFn(BlobContentViewer, {
      store: createMockStore(),
      apolloProvider: fakeApollo,
      propsData: propsMock,
      mixins: [{ data: () => ({ ref: refMock }) }],
      mocks: {
        $route: mockRoute,
        $router: mockRouter,
      },
      provide: {
        targetBranch: 'test',
        originalBranch: 'default-ref',
        ...inject,
        glFeatures: {
          highlightJs,
        },
      },
    }),
  );

  // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
  // eslint-disable-next-line no-restricted-syntax
  wrapper.setData({ project: blobInfo, isBinary });

  await waitForPromises();
};

const execImmediately = (callback) => {
  callback();
};

describe('Blob content viewer component', () => {
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBlobHeader = () => wrapper.findComponent(BlobHeader);
  const findWebIdeLink = () => wrapper.findComponent(WebIdeLink);
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
      expect(findBlobHeader().props('hideViewerSwitcher')).toEqual(true);
      expect(findBlobHeader().props('blob')).toEqual(simpleViewerMock);
      expect(mockRouterPush).not.toHaveBeenCalled();
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
      const legacyViewerUrl = 'some_file.js?format=json&viewer=simple';
      const fileType = 'text';
      const highlightJs = false;

      it('loads a legacy viewer when a the fileType is text and the highlightJs feature is turned off', async () => {
        await createComponent({
          blob: { ...simpleViewerMock, fileType, highlightJs },
        });

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].url).toBe(legacyViewerUrl);
      });

      it('loads a legacy viewer when the source viewer emits an error', async () => {
        loadViewer.mockReturnValueOnce(SourceViewer);
        await createComponent();
        findSourceViewer().vm.$emit('error');
        await waitForPromises();

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0].url).toBe(legacyViewerUrl);
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
          expect(mockAxios.history.get[0].url).toBe(`${type}?format=json&viewer=simple`);
        },
      );

      it('loads the LineHighlighter', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...simpleViewerMock, fileType, highlightJs } });
        expect(LineHighlighter).toHaveBeenCalled();
      });

      it('does not load the LineHighlighter for RichViewers', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...richViewerMock, fileType, highlightJs } });
        expect(LineHighlighter).not.toHaveBeenCalled();
      });

      it('scrolls to the hash', async () => {
        mockAxios.onGet(legacyViewerUrl).replyOnce(HTTP_STATUS_OK, 'test');
        await createComponent({ blob: { ...simpleViewerMock, fileType, highlightJs } });
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
      expect(mockAxios.history.get[0].url).toEqual('some_file.js?format=json&viewer=rich');
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
      const url = 'some_file.js?format=json&viewer=rich';
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

    it.each`
      viewer        | loadViewerReturnValue
      ${'empty'}    | ${EmptyViewer}
      ${'download'} | ${DownloadViewer}
      ${'text'}     | ${SourceViewer}
    `('renders viewer component for $viewer files', async ({ viewer, loadViewerReturnValue }) => {
      loadViewer.mockReturnValue(loadViewerReturnValue);

      createComponent({
        blob: {
          ...simpleViewerMock,
          fileType: 'null',
          simpleViewer: {
            ...simpleViewerMock.simpleViewer,
            fileType: viewer,
          },
        },
      });

      await waitForPromises();

      expect(loadViewer).toHaveBeenCalledWith(viewer, false);
      expect(wrapper.findComponent(loadViewerReturnValue).exists()).toBe(true);
    });
  });

  describe('BlobHeader action slot', () => {
    const { ideEditPath, editBlobPath } = simpleViewerMock;

    it('renders WebIdeLink button in simple viewer', async () => {
      await createComponent({ inject: { BlobContent: true, BlobReplace: true } }, mount);

      expect(findWebIdeLink().props()).toMatchObject({
        editUrl: editBlobPath,
        webIdeUrl: ideEditPath,
        showEditButton: true,
        showGitpodButton: applicationInfoMock.gitpodEnabled,
        gitpodEnabled: userInfoMock.currentUser.gitpodEnabled,
        showPipelineEditorButton: true,
        gitpodUrl: simpleViewerMock.gitpodBlobUrl,
        pipelineEditorUrl: simpleViewerMock.pipelineEditorPath,
        userPreferencesGitpodPath: userInfoMock.currentUser.preferencesGitpodPath,
        userProfileEnableGitpodPath: userInfoMock.currentUser.profileEnableGitpodPath,
      });
    });

    it('renders WebIdeLink button in rich viewer', async () => {
      await createComponent({ blob: richViewerMock }, mount);

      expect(findWebIdeLink().props()).toMatchObject({
        editUrl: editBlobPath,
        webIdeUrl: ideEditPath,
        showEditButton: true,
      });
    });

    it('renders WebIdeLink button for binary files', async () => {
      await createComponent({ blob: richViewerMock, isBinary: true }, mount);

      expect(findWebIdeLink().props()).toMatchObject({
        editUrl: editBlobPath,
        webIdeUrl: ideEditPath,
        showEditButton: false,
      });
    });

    describe('blob header binary file', () => {
      it('passes the correct isBinary value when viewing a binary file', async () => {
        await createComponent({ blob: richViewerMock, isBinary: true });

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
        expect(findWebIdeLink().props('showEditButton')).toBe(false);
      });
    });

    describe('BlobButtonGroup', () => {
      const { name, path, replacePath, webPath } = simpleViewerMock;
      const {
        userPermissions: { pushCode, downloadCode },
        repository: { empty },
      } = projectMock;

      it('renders component', async () => {
        window.gon.current_user_id = 1;
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
    it.each`
      highlightJs | shouldFetchRawText
      ${true}     | ${true}
      ${false}    | ${false}
    `(
      'calls blob info query with shouldFetchRawText: $shouldFetchRawText when highlightJs (feature flag): $highlightJs',
      async ({ highlightJs, shouldFetchRawText }) => {
        await createComponent({ highlightJs });

        expect(blobInfoMockResolver).toHaveBeenCalledWith(
          expect.objectContaining({ shouldFetchRawText }),
        );
      },
    );

    it('is called with originalBranch value if the prop has a value', async () => {
      await createComponent({ inject: { originalBranch: 'some-branch' } });

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
      findWebIdeLink().vm.$emit('edit', 'simple');
      expect(urlUtility.redirectTo).toHaveBeenCalledWith(simpleViewerMock.editBlobPath); // eslint-disable-line import/no-deprecated
    });

    it('IDE edit redirects to the IDE editor', () => {
      findWebIdeLink().vm.$emit('edit', 'ide');
      expect(urlUtility.redirectTo).toHaveBeenCalledWith(simpleViewerMock.ideEditPath); // eslint-disable-line import/no-deprecated
    });

    it.each`
      loggedIn | canModifyBlob | createMergeRequestIn | forkProject | showForkSuggestion
      ${true}  | ${false}      | ${true}              | ${true}     | ${true}
      ${false} | ${false}      | ${true}              | ${true}     | ${false}
      ${true}  | ${true}       | ${false}             | ${true}     | ${false}
      ${true}  | ${true}       | ${true}              | ${false}    | ${false}
    `(
      'shows/hides a fork suggestion according to a set of conditions',
      async ({
        loggedIn,
        canModifyBlob,
        createMergeRequestIn,
        forkProject,
        showForkSuggestion,
      }) => {
        isLoggedIn.mockReturnValueOnce(loggedIn);
        await createComponent(
          {
            blob: { ...simpleViewerMock, canModifyBlob },
            createMergeRequestIn,
            forkProject,
          },
          mount,
        );

        findWebIdeLink().vm.$emit('edit', 'simple');
        await nextTick();

        expect(findForkSuggestion().exists()).toBe(showForkSuggestion);
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
