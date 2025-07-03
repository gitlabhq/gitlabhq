import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { logError } from '~/lib/logger';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { InternalEvents } from '~/tracking';
import WebIdeLink from 'ee_else_ce/vue_shared/components/web_ide_link.vue';
import { resetShortcutsForTests } from '~/behaviors/shortcuts';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import OverflowMenu from 'ee_else_ce/repository/components/header_area/blob_overflow_menu.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import userGitpodInfo from '~/repository/queries/user_gitpod_info.query.graphql';
import applicationInfoQuery from '~/repository/queries/application_info.query.graphql';
import createRouter from '~/repository/router';
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
jest.mock('~/behaviors/shortcuts/shortcuts_toggle', () => ({
  shouldDisableShortcuts: () => false,
}));

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
    glFeatures = {},
  } = {}) => {
    const projectPath = 'some/project';
    router = createRouter(projectPath, refMock);

    await router.push({
      name: 'blobPathDecoded',
      params: { path: '/some/file.js' },
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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        projectPath,
        projectIdAsNumber: 1,
        isBinary: false,
        refType: 'heads',
        ...props,
      },
      mixins: [{ data: () => ({ ref: refMock }) }, glFeatureFlagMixin(), InternalEvents.mixin()],
      stubs: {
        WebIdeLink,
      },
    });

    await waitForPromises();
  };

  const findOpenMrBadge = () => wrapper.findComponent(OpenMrBadge);
  const findFindButton = () => wrapper.findByTestId('find');
  const findBlameButton = () => wrapper.findByTestId('blame');
  const findWebIdeLink = () => wrapper.findComponent(WebIdeLink);
  const findForkSuggestionModal = () => wrapper.findComponent(ForkSuggestionModal);
  const findOverflowMenu = () => wrapper.findComponent(OverflowMenu);
  const findOverflowMenuLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    fakeApollo = null;
    Sentry.captureException.mockRestore();
    createAlert.mockClear();
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

  describe('Find file button', () => {
    it('renders by default', () => {
      expect(findFindButton().exists()).toBe(true);
    });

    it('does not render on mobile layout', () => {
      expect(findFindButton().classes()).toContain('gl-hidden', 'sm:gl-inline-flex');
    });

    it('correctly formats tooltip', () => {
      const tooltip = getBinding(findFindButton().element, 'gl-tooltip');

      expect(findFindButton().attributes('aria-keyshortcuts')).toBe('t');
      expect(findFindButton().attributes('title')).toBe(
        'Go to find file <kbd class="flat gl-ml-1" aria-hidden="true">t</kbd>',
      );
      expect(tooltip).toBeDefined();
    });

    it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

      findFindButton().vm.$emit('click');

      expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
    });

    it('emits a tracking event when the Find file button is clicked', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

      findFindButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_find_file_button_on_repository_pages',
        {},
        undefined,
      );
    });
  });

  describe('Blame button', () => {
    it('renders a blame button with the correct href', () => {
      expect(findBlameButton().attributes('href')).toBe('blame/file.js');
    });

    it('does not render on mobile layout', () => {
      expect(findBlameButton().classes()).toContain('gl-hidden', 'sm:gl-inline-flex');
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
      const blobOverwriteResolver = overrideBlobControlsResolver({
        storedExternally: false,
        externalStorage: null,
      });
      await createComponent({ blobControlsResolver: blobOverwriteResolver });

      expect(findBlameButton().exists()).toBe(true);
    });

    it('calls trackEvent method when clicked on blame button', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findBlameButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_blame_control_on_blob_page', {}, undefined);
    });
  });

  describe('WebIdeLink component', () => {
    it('renders the WebIdeLink component with the correct props', async () => {
      const blobOverwriteResolver = overrideBlobControlsResolver({
        simpleViewer: {
          ...blobControlsDataMock.repository.blobs.nodes[0].simpleViewer,
          fileType: 'text',
        },
      });
      await createComponent({
        blobControlsResolver: blobOverwriteResolver,
      });
      expect(findWebIdeLink().props()).toMatchObject({
        editUrl: 'https://edit/blob/path/file.js',
        webIdeUrl: 'https://ide/blob/path/file.js',
        needsToFork: false,
        needsToForkWithWebIde: false,
        showPipelineEditorButton: true,
        pipelineEditorUrl: 'pipeline/editor/path/file.yml',
        gitpodUrl: 'gitpod/blob/url/file.js',
        isGitpodEnabledForInstance: true,
        isGitpodEnabledForUser: true,
        disabled: false,
        customTooltipText: '',
      });
    });

    describe('when project query has errors', () => {
      it('disables the WebIdeLink component with appropriate tooltip', async () => {
        await createComponent({ blobControlsResolver: blobControlsErrorResolver });

        expect(findWebIdeLink().props('disabled')).toBe(true);
        expect(findWebIdeLink().props('customTooltipText')).toBe(
          'An error occurred while loading file controls. Refresh the page.',
        );
      });
    });

    describe.each`
      description           | overrides                                                                | expectedTooltip
      ${'file is archived'} | ${{ ...blobControlsDataMock.repository.blobs.nodes[0], archived: true }} | ${'You cannot edit files in archived projects'}
      ${'file is LFS'}      | ${{ storedExternally: true, externalStorage: 'lfs' }}                    | ${'You cannot edit files stored in LFS'}
    `('when $description', ({ overrides, expectedTooltip }) => {
      it('disables the WebIdeLink component with appropriate tooltip', async () => {
        const customBlobControlsResolver = (() => {
          return overrideBlobControlsResolver(overrides);
        })();
        await createComponent({
          blobControlsResolver: customBlobControlsResolver,
        });

        expect(findWebIdeLink().props('disabled')).toBe(true);
        expect(findWebIdeLink().props('customTooltipText')).toBe(expectedTooltip);
      });
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
    it('renders a spinner for BlobOverflowMenu when loading repository blob data', async () => {
      const loadingBlobControlsResolver = jest.fn().mockResolvedValue(new Promise(() => {}));
      await createComponent({
        blobControlsResolver: loadingBlobControlsResolver,
      });
      expect(findOverflowMenuLoadingIcon().exists()).toBe(true);
    });

    it('does not render a spinner for BlobOverflowMenu when not loading repository blob data', () => {
      expect(findOverflowMenuLoadingIcon().exists()).toBe(false);
    });

    it('renders BlobOverflow component with correct props', () => {
      expect(findOverflowMenu().exists()).toBe(true);
      expect(findOverflowMenu().props()).toMatchObject({
        projectPath: 'some/project',
        isBinaryFileType: true,
        overrideCopy: true,
        isEmptyRepository: false,
        isUsingLfs: false,
      });
    });

    it('passes the correct isBinary value to BlobOverflow when viewing a binary file', async () => {
      await createComponent({
        props: {
          isBinary: true,
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

    it('proxy locked-file event', async () => {
      findOverflowMenu().vm.$emit('lockedFile', true);
      await nextTick();

      expect(wrapper.emitted('lockedFile')).toEqual([[true]]);
    });
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
          message: 'An error occurred while loading file controls. Refresh the page.',
        });
        expect(logError).toHaveBeenCalledWith(loggedError, mockError);
        expect(Sentry.captureException).toHaveBeenCalledWith(mockError);
      },
    );
  });
});
