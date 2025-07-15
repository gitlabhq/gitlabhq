import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefSelector from '~/ref/components/ref_selector.vue';
import HeaderArea from '~/repository/components/header_area.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';
import AddToTree from '~/repository/components/header_area/add_to_tree.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { headerAppInjected } from 'ee_else_ce_jest/repository/mock_data';
import CompactCodeDropdown from 'ee_else_ce/repository/components/code_dropdown/compact_code_dropdown.vue';

const defaultMockRoute = {
  params: {
    path: 'index.js',
  },
  meta: {
    refType: '',
  },
  query: {
    ref_type: '',
  },
};

const mockRootRef = 'root-ref';

describe('HeaderArea', () => {
  let wrapper;

  const findBreadcrumbs = () => wrapper.findComponent(Breadcrumbs);
  const findRefSelector = () => wrapper.findComponent(RefSelector);
  const findFindFileButton = () => wrapper.findByTestId('tree-find-file-control');
  const findWebIdeButton = () => wrapper.findByTestId('js-tree-web-ide-link');
  const findCodeDropdown = () => wrapper.findComponent(CodeDropdown);
  const findSourceCodeDownloadDropdown = () => wrapper.findComponent(SourceCodeDownloadDropdown);
  const findCloneCodeDropdown = () => wrapper.findComponent(CloneCodeDropdown);
  const findCompactCodeDropdown = () => wrapper.findComponent(CompactCodeDropdown);
  const findAddToTreeDropdown = () => wrapper.findComponent(AddToTree);
  const findPageHeading = () => wrapper.findByTestId('repository-heading');
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const findRepositoryOverflowMenu = () => wrapper.findComponent(RepositoryOverflowMenu);
  const findBlobControls = () => wrapper.findComponent(BlobControls);
  const findTreeControls = () => wrapper.findByTestId('tree-controls-container');

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = ({
    props = {},
    route = { name: 'blobPathDecoded' },
    provided = {
      rootRef: mockRootRef,
    },
  } = {}) => {
    return shallowMountExtended(HeaderArea, {
      provide: {
        ...headerAppInjected,
        ...provided,
      },
      propsData: {
        projectPath: 'test/project',
        historyLink: '/history',
        refType: 'branch',
        projectId: '123',
        currentRef: 'main',
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
        CompactCodeDropdown,
      },
      mocks: {
        $route: {
          ...defaultMockRoute,
          ...route,
          params: {
            ...defaultMockRoute.params,
            ...(route.params || {}),
          },
        },
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders the component', () => {
    expect(wrapper.exists()).toBe(true);
  });

  describe('Ref selector', () => {
    it('renders correctly', () => {
      expect(findRefSelector().props('defaultBranch')).toBe(mockRootRef);
    });

    it('renders correctly when branch names ending with .json', () => {
      createComponent({ props: { refSelectorValue: 'ends-with.json' } });
      expect(findRefSelector().exists()).toBe(true);
    });
  });

  it('renders Breadcrumbs component', () => {
    expect(findBreadcrumbs().exists()).toBe(true);
  });

  it('renders PageHeading component', () => {
    expect(findPageHeading().exists()).toBe(true);
  });

  describe('showTreeControls', () => {
    it('should not render tree controls for blob view', () => {
      wrapper = createComponent({}, { name: 'blobPathDecoded' });
      expect(findTreeControls().exists()).toBe(false);
    });
  });

  describe('when rendered for tree view', () => {
    beforeEach(() => {
      wrapper = createComponent({
        route: { name: 'treePathDecoded', params: { path: 'project' } },
      });
    });

    describe('PageHeading', () => {
      it('displays correct directory name', () => {
        expect(findPageHeading().text()).toContain('project');
        expect(findFileIcon().props('fileName')).toBe('folder-open');
        expect(findFileIcon().props('folder')).toBe(true);
        expect(findFileIcon().classes('gl-text-subtle')).toBe(true);
      });
    });

    describe('Find file button', () => {
      it('renders Find file button', () => {
        expect(findFindFileButton().exists()).toBe(true);
      });

      it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
        jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();
        findFindFileButton().vm.$emit('click');

        expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
      });

      it('emits a tracking event when the Find file button is clicked', () => {
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
        jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();

        findFindFileButton().vm.$emit('click');

        expect(trackEventSpy).toHaveBeenCalledWith('click_find_file_button_on_repository_pages');
      });
    });

    describe('Edit button', () => {
      it('renders WebIdeLink component', () => {
        expect(findWebIdeButton().exists()).toBe(true);
      });
    });

    describe('when `directory_code_dropdown_updates` flag is `false`', () => {
      describe('CodeDropdown', () => {
        it('renders CodeDropdown component with correct props for desktop layout', () => {
          expect(findCodeDropdown().exists()).toBe(true);
          expect(findCodeDropdown().props('sshUrl')).toBe(headerAppInjected.sshUrl);
          expect(findCodeDropdown().props('httpUrl')).toBe(headerAppInjected.httpUrl);
        });

        describe('SourceCodeDownloadDropdown', () => {
          it('renders SourceCodeDownloadDropdown and CloneCodeDropdown component with correct props for mobile layout', () => {
            expect(findSourceCodeDownloadDropdown().exists()).toBe(true);
            expect(findSourceCodeDownloadDropdown().props('downloadLinks')).toEqual(
              headerAppInjected.downloadLinks,
            );
            expect(findSourceCodeDownloadDropdown().props('downloadArtifacts')).toEqual(
              headerAppInjected.downloadArtifacts,
            );
            expect(findCloneCodeDropdown().exists()).toBe(true);
            expect(findCloneCodeDropdown().props('sshUrl')).toBe(headerAppInjected.sshUrl);
            expect(findCloneCodeDropdown().props('httpUrl')).toBe(headerAppInjected.httpUrl);
          });
        });

        describe('Add to tree dropdown', () => {
          it('does not render AddToTree component', () => {
            expect(findAddToTreeDropdown().exists()).toBe(false);
          });
        });
      });
    });
  });

  describe('when rendered for tree view and directory_code_dropdown_updates flag is true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        route: { name: 'treePathDecoded' },
        provided: {
          glFeatures: {
            directoryCodeDropdownUpdates: true,
          },
          newWorkspacePath: '/workspaces/new',
          organizationId: '1',
        },
      });
    });

    describe('Add to tree dropdown', () => {
      it('renders AddToTree component', () => {
        expect(findAddToTreeDropdown().exists()).toBe(true);
      });
    });

    it('renders CompactCodeDropdown with correct props', () => {
      expect(findCompactCodeDropdown().exists()).toBe(true);
      expect(findCompactCodeDropdown().props()).toMatchObject({
        sshUrl: headerAppInjected.sshUrl,
        httpUrl: headerAppInjected.httpUrl,
        kerberosUrl: headerAppInjected.kerberosUrl,
        xcodeUrl: headerAppInjected.xcodeUrl,
        webIdeUrl: headerAppInjected.webIdeUrl,
        gitpodUrl: headerAppInjected.gitpodUrl,
        showWebIdeButton: headerAppInjected.showWebIdeButton,
        isGitpodEnabledForInstance: headerAppInjected.isGitpodEnabledForInstance,
        isGitpodEnabledForUser: headerAppInjected.isGitpodEnabledForUser,
        currentPath: defaultMockRoute.params.path,
        directoryDownloadLinks: headerAppInjected.downloadLinks,
      });
    });

    describe('RepositoryOverflowMenu', () => {
      it('renders RepositoryOverflowMenu component with correct props when on default branch', () => {
        wrapper = createComponent({
          route: { name: 'treePathDecoded' },
        });
        expect(findRepositoryOverflowMenu().props()).toStrictEqual({
          currentRef: 'main',
          fullPath: 'test/project',
          path: 'index.js',
        });
      });

      it('renders RepositoryOverflowMenu component with correct props when on non-default branch', () => {
        wrapper = createComponent({
          route: { name: 'treePathDecoded' },
          provided: { comparePath: 'test/project/compare' },
        });
        expect(findRepositoryOverflowMenu().props()).toStrictEqual({
          currentRef: 'main',
          fullPath: 'test/project',
          path: 'index.js',
        });
      });
    });
  });

  describe('when rendered for blob view', () => {
    describe('showBlobControls', () => {
      it('should not render blob controls when filePath does not exist', () => {
        wrapper = createComponent({ route: { name: 'blobPathDecoded', params: { path: null } } });
        expect(findBlobControls().exists()).toBe(false);
      });

      it('should not render blob controls when route name is not blobPathDecoded', () => {
        wrapper = createComponent({
          route: { name: 'blobPath', params: { path: '/some/file.js' } },
        });
        expect(findBlobControls().exists()).toBe(false);
      });
    });

    it('renders BlobControls component with correct props', () => {
      wrapper = createComponent({ props: { refType: 'branch' } });
      expect(findBlobControls().exists()).toBe(true);
      expect(findBlobControls().props('projectPath')).toBe('test/project');
      expect(findBlobControls().props('refType')).toBe('');
    });

    it('does not render CodeDropdown and SourceCodeDownloadDropdown', () => {
      expect(findCodeDropdown().exists()).toBe(false);
      expect(findSourceCodeDownloadDropdown().exists()).toBe(false);
    });

    it('does not render AddToTree component', () => {
      expect(findAddToTreeDropdown().exists()).toBe(false);
    });

    it('displays correct file name and icon', () => {
      expect(findPageHeading().text()).toContain('index.js');
      expect(findFileIcon().props('fileName')).toBe('index.js');
      expect(findFileIcon().props('folder')).toBe(false);
      expect(findFileIcon().classes('gl-text-subtle')).toBe(false);
    });
  });

  describe('when rendered for readme project overview', () => {
    describe('when directory_code_dropdown_updates flag is false', () => {
      beforeEach(() => {
        wrapper = createComponent({
          route: { name: 'treePathDecoded' },
          provided: { isReadmeView: true },
        });
      });

      it('does not render directory name and icon', () => {
        expect(findPageHeading().exists()).toBe(false);
        expect(findFileIcon().exists()).toBe(false);
      });

      it('does not render RefSelector or Breadcrumbs', () => {
        expect(findRefSelector().exists()).toBe(false);
        expect(findBreadcrumbs().exists()).toBe(false);
      });

      it('does not render AddToTree component', () => {
        expect(findAddToTreeDropdown().exists()).toBe(false);
      });

      it('does not render CodeDropdown and SourceCodeDownloadDropdown', () => {
        expect(findCodeDropdown().exists()).toBe(false);
        expect(findSourceCodeDownloadDropdown().exists()).toBe(false);
      });

      it('does not render CompactCodeDropdown', () => {
        expect(findCompactCodeDropdown().exists()).toBe(false);
      });
    });

    describe('when directory_code_dropdown_updates flag is true', () => {
      beforeEach(() => {
        wrapper = createComponent({
          route: { name: 'treePathDecoded' },
          provided: {
            glFeatures: {
              directoryCodeDropdownUpdates: true,
            },
            newWorkspacePath: '/workspaces/new',
            organizationId: '1',
            isReadmeView: true,
          },
        });
      });

      it('does render CompactCodeDropdown', () => {
        expect(findCompactCodeDropdown().exists()).toBe(true);
      });

      it('does not render directory name and icon', () => {
        expect(findPageHeading().exists()).toBe(false);
        expect(findFileIcon().exists()).toBe(false);
      });

      it('does not render RefSelector or Breadcrumbs', () => {
        expect(findRefSelector().exists()).toBe(false);
        expect(findBreadcrumbs().exists()).toBe(false);
      });

      it('does not render AddToTree component', () => {
        expect(findAddToTreeDropdown().exists()).toBe(false);
      });

      it('does not render CodeDropdown and SourceCodeDownloadDropdown', () => {
        expect(findCodeDropdown().exists()).toBe(false);
        expect(findSourceCodeDownloadDropdown().exists()).toBe(false);
      });
    });
  });

  describe('when rendered for full project overview', () => {
    beforeEach(() => {
      wrapper = createComponent({ route: { name: 'projectRoot' } });
    });

    it('does not render directory name and icon', () => {
      expect(findPageHeading().exists()).toBe(false);
      expect(findFileIcon().exists()).toBe(false);
    });

    it('renders refSelector, breadcrumbs and tree controls with correct layout', () => {
      expect(wrapper.find('section').classes()).toEqual([
        'gl-items-center',
        'gl-justify-between',
        'sm:gl-flex',
      ]);
    });
  });
});
