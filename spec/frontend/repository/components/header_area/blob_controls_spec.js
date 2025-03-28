import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { logError } from '~/lib/logger';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WebIdeLink from 'ee_else_ce/vue_shared/components/web_ide_link.vue';
import { resetShortcutsForTests } from '~/behaviors/shortcuts';
import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import OverflowMenu from 'ee_else_ce/repository/components/header_area/blob_overflow_menu.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import userGitpodInfo from '~/repository/queries/user_gitpod_info.query.graphql';
import applicationInfoQuery from '~/blob/queries/application_info.query.graphql';
import createRouter from '~/repository/router';
import { updateElementsVisibility } from '~/repository/utils/dom';
import OpenMrBadge from '~/repository/components/header_area/open_mr_badge.vue';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';
import {
  blobControlsDataMock,
  refMock,
  currentUserDataMock,
  applicationInfoMock,
} from '../../mock_data';

Vue.use(VueApollo);
jest.mock('~/repository/utils/dom');
jest.mock('~/behaviors/shortcuts/shortcuts_blob');
jest.mock('~/blob/blob_line_permalink_updater');
jest.mock('~/alert');
jest.mock('~/lib/logger');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));
jest.mock('~/lib/utils/common_utils', () => ({
  isLoggedIn: jest.fn().mockReturnValue(true),
}));
jest.mock('~/sentry/sentry_browser_wrapper');

describe('Blob controls component', () => {
  let router;
  let wrapper;
  let fakeApollo;

  const blobControlsSuccessResolver = jest.fn().mockResolvedValue({
    data: { project: blobControlsDataMock },
  });
  const blobControlsErrorResolver = jest.fn().mockRejectedValue(new Error('Request failed'));
  const overrideBlobControlsResolver = (blobControlsOverrides = {}) => {
    return jest.fn().mockResolvedValue({
      data: {
        project: {
          ...blobControlsDataMock,
          repository: {
            ...blobControlsDataMock.repository,
            blobs: {
              ...blobControlsDataMock.repository.blobs,
              nodes: [
                { ...blobControlsDataMock.repository.blobs.nodes[0], ...blobControlsOverrides },
              ],
            },
          },
        },
      },
    });
  };

  const currentUserSuccessResolver = jest
    .fn()
    .mockResolvedValue({ data: { currentUser: currentUserDataMock } });
  const currentUserErrorResolver = jest.fn().mockRejectedValue(new Error('Request failed'));

  const applicationInfoSuccessResolver = jest.fn().mockResolvedValue({
    data: { ...applicationInfoMock },
  });
  const applicationInfoErrorResolver = jest.fn().mockRejectedValue(new Error('Request failed'));

  const createComponent = async ({
    props = {},
    blobControlsResolver = blobControlsSuccessResolver,
    currentUserResolver = currentUserSuccessResolver,
    applicationInfoResolver = applicationInfoSuccessResolver,
    glFeatures = { blobOverflowMenu: false },
    routerOverride = {},
  } = {}) => {
    const projectPath = 'some/project';
    router = createRouter(projectPath, refMock);

    await router.push({
      name: 'blobPathDecoded',
      params: { path: '/some/file.js' },
      ...routerOverride,
    });

    await resetShortcutsForTests();

    fakeApollo = createMockApollo([
      [blobControlsQuery, blobControlsResolver],
      [userGitpodInfo, currentUserResolver],
      [applicationInfoQuery, applicationInfoResolver],
    ]);

    wrapper = shallowMountExtended(BlobControls, {
      router,
      apolloProvider: fakeApollo,
      provide: {
        glFeatures,
        currentRef: refMock,
      },
      propsData: {
        projectPath,
        projectIdAsNumber: 1,
        isBinary: false,
        refType: 'heads',
        ...props,
      },
      mixins: [{ data: () => ({ ref: refMock }) }, glFeatureFlagMixin()],
      stubs: {
        WebIdeLink,
      },
    });

    await waitForPromises();
  };

  const findOpenMrBadge = () => wrapper.findComponent(OpenMrBadge);
  const findFindButton = () => wrapper.findByTestId('find');
  const findBlameButton = () => wrapper.findByTestId('blame');
  const findPermalinkButton = () => wrapper.findByTestId('permalink');
  const findWebIdeLink = () => wrapper.findComponent(WebIdeLink);
  const findForkSuggestionModal = () => wrapper.findComponent(ForkSuggestionModal);
  const findOverflowMenu = () => wrapper.findComponent(OverflowMenu);
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(async () => {
    createAlert.mockClear();
    await createComponent();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  describe('showBlobControls', () => {
    it('should not render blob controls when filePath does not exist', async () => {
      await createComponent({
        routerOverride: { name: 'blobPathDecoded', params: null },
      });
      expect(wrapper.element).not.toBeVisible();
    });

    it('should not render blob controls when route name is not blobPathDecoded', async () => {
      await createComponent({
        routerOverride: { name: 'blobPath', params: { path: '/some/file.js' } },
      });
      expect(wrapper.element).not.toBeVisible();
    });
  });

  it.each`
    name                 | path
    ${'blobPathDecoded'} | ${null}
    ${'treePathDecoded'} | ${'myFile.js'}
  `(
    'does not render any buttons if router name is $name and router path is $path',
    async ({ name, path }) => {
      await router.replace({ name, params: { path } });

      await nextTick();

      expect(findFindButton().exists()).toBe(false);
      expect(findBlameButton().exists()).toBe(false);
      expect(findPermalinkButton().exists()).toBe(false);
      expect(updateElementsVisibility).toHaveBeenCalledWith('.tree-controls', true);
    },
  );

  it('loads the ShortcutsBlob', () => {
    expect(ShortcutsBlob).toHaveBeenCalled();
  });

  it('loads the BlobLinePermalinkUpdater', () => {
    expect(BlobLinePermalinkUpdater).toHaveBeenCalled();
  });

  describe('Error handling', () => {
    it.each`
      scenario                   | resolverParam                                                | loggedError
      ${'blobControls query'}    | ${{ blobControlsResolver: blobControlsErrorResolver }}       | ${'Failed to fetch blob controls. See exception details for more information.'}
      ${'currentUser query'}     | ${{ currentUserResolver: currentUserErrorResolver }}         | ${'Failed to fetch current user. See exception details for more information.'}
      ${'applicationInfo query'} | ${{ applicationInfoResolver: applicationInfoErrorResolver }} | ${'Failed to fetch application info. See exception details for more information.'}
    `(
      'renders an alert and logs the error if the $scenario fails',
      async ({ resolverParam, loggedError }) => {
        const mockError = new Error('Request failed');
        await createComponent(resolverParam);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while loading the blob controls.',
        });
        expect(logError).toHaveBeenCalledWith(loggedError, mockError);
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      },
    );
  });

  describe('MR badge', () => {
    it('should render the badge if `filter_blob_path` flag is on', async () => {
      await createComponent({ glFeatures: { filterBlobPath: true } });
      expect(findOpenMrBadge().exists()).toBe(true);
      expect(findOpenMrBadge().props('blobPath')).toBe('/some/file.js');
      expect(findOpenMrBadge().props('projectPath')).toBe('some/project');
    });

    it('should not render the badge if `filter_blob_path` flag is off', async () => {
      await createComponent({ glFeatures: { filterBlobPath: false } });
      expect(findOpenMrBadge().exists()).toBe(false);
    });
  });

  describe('FindFile button', () => {
    it('renders FindFile button', () => {
      expect(findFindButton().exists()).toBe(true);
    });

    it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
      const findFileButton = findFindButton();
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();
      findFileButton.vm.$emit('click');

      expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
    });

    it('emits a tracking event when the Find file button is clicked', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

      findFindButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_find_file_button_on_repository_pages');
    });
  });

  describe('Blame button', () => {
    it('renders a blame button with the correct href', () => {
      expect(findBlameButton().attributes('href')).toBe('blame/file.js');
    });

    it('does not render blame button when blobInfo.storedExternally is true', async () => {
      const blobOverwriteResolver = overrideBlobControlsResolver({ storedExternally: true });
      await createComponent({ blobControlsResolver: blobOverwriteResolver });

      expect(findBlameButton().exists()).toBe(false);
    });

    it('does not render blame button when blobInfo.externalStorage is "lfs"', async () => {
      const blobOverwriteResolver = overrideBlobControlsResolver({
        storedExternally: true,
        externalStorage: 'lfs',
      });
      await createComponent({ blobControlsResolver: blobOverwriteResolver });

      expect(findBlameButton().exists()).toBe(false);
    });

    it('renders blame button when blobInfo.storedExternally is false and externalStorage is not "lfs"', async () => {
      await createComponent({}, { storedExternally: false, externalStorage: null });

      expect(findBlameButton().exists()).toBe(true);
    });
  });

  it('renders a permalink button with the correct href', () => {
    expect(findPermalinkButton().attributes('href')).toBe('permalink/file.js');
  });

  it('does not render WebIdeLink component', () => {
    expect(findWebIdeLink().exists()).toBe(false);
  });

  describe('when blobOverflowMenu feature flag is true', () => {
    beforeEach(async () => {
      await createComponent({ glFeatures: { blobOverflowMenu: true } });
    });

    describe('Find file button', () => {
      it('does not render on mobile layout', () => {
        expect(findFindButton().classes()).toContain('gl-hidden', 'sm:gl-inline-flex');
      });
    });

    describe('Blame button', () => {
      it('does not render on mobile layout', () => {
        expect(findBlameButton().classes()).toContain('gl-hidden', 'sm:gl-inline-flex');
      });
    });

    describe('WebIdeLink component', () => {
      it('renders the WebIdeLink component with the correct props', () => {
        expect(findWebIdeLink().props()).toMatchObject({
          showEditButton: false,
          editUrl: 'https://edit/blob/path/file.js',
          webIdeUrl: 'https://ide/blob/path/file.js',
          needsToFork: false,
          needsToForkWithWebIde: false,
          showPipelineEditorButton: true,
          pipelineEditorUrl: 'pipeline/editor/path/file.yml',
          gitpodUrl: 'gitpod/blob/url/file.js',
          isGitpodEnabledForInstance: true,
          isGitpodEnabledForUser: true,
        });
      });

      it('does not render WebIdeLink component if file is archived', async () => {
        const blobOverwriteResolver = overrideBlobControlsResolver({
          ...blobControlsDataMock.repository.blobs.nodes[0],
          archived: true,
        });
        await createComponent({
          blobControlsResolver: blobOverwriteResolver,
          glFeatures: { blobOverflowMenu: true },
        });

        expect(findWebIdeLink().exists()).toBe(false);
      });

      it('does not render WebIdeLink component if file is not editable', async () => {
        const blobOverwriteResolver = overrideBlobControlsResolver({
          ...blobControlsDataMock.repository.blobs.nodes[0],
          editBlobPath: '',
        });
        await createComponent({
          blobControlsResolver: blobOverwriteResolver,
          glFeatures: { blobOverflowMenu: true },
        });

        expect(findWebIdeLink().exists()).toBe(false);
      });

      describe('when can modify blob', () => {
        it('redirects to WebIDE to edit the file', async () => {
          findWebIdeLink().vm.$emit('edit', 'ide');
          await nextTick();

          expect(visitUrl).toHaveBeenCalledWith('https://ide/blob/path/file.js');
          expect(findForkSuggestionModal().props('visible')).toBe(false);
        });

        it('redirects to single file editor to edit the file', async () => {
          findWebIdeLink().vm.$emit('edit', 'simple');
          await nextTick();

          expect(visitUrl).toHaveBeenCalledWith('https://edit/blob/path/file.js');
          expect(findForkSuggestionModal().props('visible')).toBe(false);
        });
      });

      describe('when user cannot modify blob', () => {
        it('changes ForkSuggestionModal visibility', async () => {
          const blobControlsForForkResolver = jest.fn().mockResolvedValue({
            data: {
              project: {
                ...blobControlsDataMock,
                userPermissions: {
                  ...blobControlsDataMock.userPermissions,
                  pushCode: false,
                  createMergeRequestIn: true,
                },
                repository: {
                  ...blobControlsDataMock.repository,
                  blobs: {
                    ...blobControlsDataMock.repository.blobs,
                    nodes: [
                      {
                        ...blobControlsDataMock.repository.blobs.nodes[0],
                        canModifyBlob: false,
                        canModifyBlobWithWebIde: false,
                      },
                    ],
                  },
                },
              },
            },
          });
          await createComponent({
            blobControlsResolver: blobControlsForForkResolver,
            glFeatures: { blobOverflowMenu: true },
          });

          findWebIdeLink().vm.$emit('edit', 'simple');
          await nextTick();

          expect(findForkSuggestionModal().props('visible')).toBe(true);
        });
      });
    });

    describe('ForkSuggestionModal component', () => {
      it('renders ForkSuggestionModal', () => {
        expect(findForkSuggestionModal().exists()).toBe(true);
        expect(findForkSuggestionModal().props()).toMatchObject({
          visible: false,
          forkPath: 'fork/view/path',
        });
      });
    });

    describe('BlobOverflow dropdown', () => {
      it('renders BlobOverflow component with correct props', () => {
        expect(findOverflowMenu().exists()).toBe(true);
        expect(findOverflowMenu().props()).toEqual({
          projectPath: 'some/project',
          isBinaryFileType: true,
          overrideCopy: true,
          isEmptyRepository: false,
          isUsingLfs: false,
          eeCanLock: undefined,
          eeCanModifyFile: undefined,
          eeIsLocked: undefined,
        });
      });

      it('passes the correct isBinary value to BlobOverflow when viewing a binary file', async () => {
        await createComponent({
          props: {
            isBinary: true,
          },
          glFeatures: {
            blobOverflowMenu: true,
          },
        });

        expect(findOverflowMenu().props('isBinaryFileType')).toBe(true);
      });

      it('copies to clipboard raw blob text, when receives copy event', () => {
        jest.spyOn(navigator.clipboard, 'writeText');
        findOverflowMenu().vm.$emit('copy');

        expect(navigator.clipboard.writeText).toHaveBeenCalledWith('Example raw text content');
      });

      it('changes ForkSuggestionModal visibility when receives showForkSuggestion event', async () => {
        findOverflowMenu().vm.$emit('showForkSuggestion');
        await nextTick();

        expect(findForkSuggestionModal().props('visible')).toBe(true);
      });
    });
  });
});
