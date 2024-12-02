import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefSelector from '~/ref/components/ref_selector.vue';
import HeaderArea from '~/repository/components/header_area.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

const defaultMockRoute = {
  params: {
    path: '',
  },
  meta: {
    refType: '',
  },
  query: {
    ref_type: '',
  },
};

const defaultProvided = {
  canCollaborate: true,
  canEditTree: true,
  canPushCode: true,
  originalBranch: 'main',
  selectedBranch: 'feature/new-ui',
  newBranchPath: '/project/new-branch',
  newTagPath: '/project/new-tag',
  newBlobPath: '/project/new-file',
  forkNewBlobPath: '/project/fork/new-file',
  forkNewDirectoryPath: '/project/fork/new-directory',
  forkUploadBlobPath: '/project/fork/upload',
  uploadPath: '/project/upload',
  newDirPath: '/project/new-directory',
  projectRootPath: '/project/root/path',
  comparePath: undefined,
  isReadmeView: false,
  isFork: false,
  needsToFork: true,
  gitpodEnabled: false,
  isBlob: true,
  showEditButton: true,
  showWebIdeButton: true,
  showGitpodButton: false,
  showPipelineEditorUrl: true,
  webIdeUrl: 'https://gitlab.com/project/-/ide/',
  editUrl: 'https://gitlab.com/project/-/edit/main/',
  pipelineEditorUrl: 'https://gitlab.com/project/-/ci/editor',
  gitpodUrl: 'https://gitpod.io/#https://gitlab.com/project',
  userPreferencesGitpodPath: '/profile/preferences#gitpod',
  userProfileEnableGitpodPath: '/profile/preferences?enable_gitpod=true',
  httpUrl: 'https://gitlab.com/example-group/example-project.git',
  xcodeUrl: 'xcode://clone?repo=https://gitlab.com/example-group/example-project.git',
  sshUrl: 'git@gitlab.com:example-group/example-project.git',
  kerberosUrl: 'https://kerberos@gitlab.com/example-group/example-project.git',
  downloadLinks: [
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.zip',
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.tar.gz',
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.tar.bz2',
    'https://gitlab.com/example-group/example-project/-/releases',
  ],
  downloadArtifacts: [
    'https://gitlab.com/example-group/example-project/-/jobs/artifacts/main/download?job=build',
  ],
};

describe('HeaderArea', () => {
  let wrapper;

  const findBreadcrumbs = () => wrapper.findComponent(Breadcrumbs);
  const findRefSelector = () => wrapper.findComponent(RefSelector);
  const findFindFileButton = () => wrapper.findByTestId('tree-find-file-control');
  const findCompareButton = () => wrapper.findByTestId('tree-compare-control');
  const findWebIdeButton = () => wrapper.findByTestId('js-tree-web-ide-link');
  const findCodeDropdown = () => wrapper.findComponent(CodeDropdown);
  const findSourceCodeDownloadDropdown = () => wrapper.findComponent(SourceCodeDownloadDropdown);
  const findCloneCodeDropdown = () => wrapper.findComponent(CloneCodeDropdown);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = (props = {}, routeName = 'blobPathDecoded', provided = {}) => {
    return shallowMountExtended(HeaderArea, {
      provide: {
        ...defaultProvided,
        ...provided,
      },
      propsData: {
        projectPath: 'test/project',
        historyLink: '/history',
        refType: 'branch',
        projectId: '123',
        refSelectorValue: 'refs/heads/main',
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $route: {
          ...defaultMockRoute,
          name: routeName,
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

  it('renders RefSelector', () => {
    expect(findRefSelector().exists()).toBe(true);
  });

  it('renders Breadcrumbs component', () => {
    expect(findBreadcrumbs().exists()).toBe(true);
  });

  describe('when rendered for tree view', () => {
    beforeEach(() => {
      wrapper = createComponent({}, 'treePathDecoded');
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

    describe('Compare button', () => {
      it('does not render Compare button for root ref', () => {
        expect(findCompareButton().exists()).not.toBe(true);
      });

      it('renders Compare button for non-root ref', () => {
        wrapper = createComponent({}, 'treePathDecoded', { comparePath: 'test/project/compare' });
        expect(findCompareButton().exists()).toBe(true);
      });
    });

    describe('Edit button', () => {
      it('renders WebIdeLink component', () => {
        expect(findWebIdeButton().exists()).toBe(true);
      });
    });

    describe('CodeDropdown', () => {
      it('renders CodeDropdown component with correct props for desktop layout', () => {
        expect(findCodeDropdown().exists()).toBe(true);
        expect(findCodeDropdown().props('sshUrl')).toBe(defaultProvided.sshUrl);
        expect(findCodeDropdown().props('httpUrl')).toBe(defaultProvided.httpUrl);
      });
    });

    describe('SourceCodeDownloadDropdown', () => {
      it('renders SourceCodeDownloadDropdown and CloneCodeDropdown component with correct props for mobile layout', () => {
        expect(findSourceCodeDownloadDropdown().exists()).toBe(true);
        expect(findSourceCodeDownloadDropdown().props('downloadLinks')).toEqual(
          defaultProvided.downloadLinks,
        );
        expect(findSourceCodeDownloadDropdown().props('downloadArtifacts')).toEqual(
          defaultProvided.downloadArtifacts,
        );
        expect(findCloneCodeDropdown().exists()).toBe(true);
        expect(findCloneCodeDropdown().props('sshUrl')).toBe(defaultProvided.sshUrl);
        expect(findCloneCodeDropdown().props('httpUrl')).toBe(defaultProvided.httpUrl);
      });
    });
  });

  describe('when rendered for blob view', () => {
    it('renders BlobControls component with correct props', () => {
      wrapper = createComponent({ refType: 'branch' });
      const blobControls = wrapper.findComponent(BlobControls);
      expect(blobControls.exists()).toBe(true);
      expect(blobControls.props('projectPath')).toBe('test/project');
      expect(blobControls.props('refType')).toBe('');
    });

    it('does not render CodeDropdown and SourceCodeDownloadDropdown', () => {
      expect(findCodeDropdown().exists()).toBe(false);
      expect(findSourceCodeDownloadDropdown().exists()).toBe(false);
    });
  });

  describe('when isReadmeView is true', () => {
    beforeEach(() => {
      wrapper = createComponent({}, 'treePathDecoded', { isReadmeView: true });
    });

    it('does not render RefSelector or Breadcrumbs', () => {
      expect(findRefSelector().exists()).toBe(false);
      expect(findBreadcrumbs().exists()).toBe(false);
    });

    it('does not render CodeDropdown and SourceCodeDownloadDropdown', () => {
      expect(findCodeDropdown().exists()).toBe(false);
      expect(findSourceCodeDownloadDropdown().exists()).toBe(false);
    });
  });
});
