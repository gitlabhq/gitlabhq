import { RouterLinkStub } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefSelector from '~/ref/components/ref_selector.vue';
import HeaderArea from '~/repository/components/header_area.vue';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import CodeDropdown from '~/vue_shared/components/code_dropdown/code_dropdown.vue';
import CompactCodeDropdown from '~/repository/components/code_dropdown/compact_code_dropdown.vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import RepositoryOverflowMenu from '~/repository/components/header_area/repository_overflow_menu.vue';
import BlobControls from '~/repository/components/header_area/blob_controls.vue';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { headerAppInjected } from 'ee_else_ce_jest/repository/mock_data';

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

describe('HeaderArea', () => {
  let wrapper;

  const findBreadcrumbs = () => wrapper.findComponent(Breadcrumbs);
  const findRefSelector = () => wrapper.findComponent(RefSelector);
  const findFindFileButton = () => wrapper.findByTestId('tree-find-file-control');
  const findWebIdeButton = () => wrapper.findByTestId('js-tree-web-ide-link');
  const findCodeDropdown = () => wrapper.findComponent(CodeDropdown);
  const findCompactCodeDropdown = () => wrapper.findComponent(CompactCodeDropdown);
  const findSourceCodeDownloadDropdown = () => wrapper.findComponent(SourceCodeDownloadDropdown);
  const findCloneCodeDropdown = () => wrapper.findComponent(CloneCodeDropdown);
  const findPageHeading = () => wrapper.findByTestId('repository-heading');
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const findRepositoryOverflowMenu = () => wrapper.findComponent(RepositoryOverflowMenu);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const createComponent = (props = {}, route = { name: 'blobPathDecoded' }, provided = {}) => {
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
        refSelectorValue: 'refs/heads/main',
        ...props,
      },
      stubs: {
        RouterLink: RouterLinkStub,
      },
      mocks: {
        $route: {
          ...defaultMockRoute,
          ...route,
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

  it('renders PageHeading component', () => {
    expect(findPageHeading().exists()).toBe(true);
  });

  describe('when rendered for tree view', () => {
    beforeEach(() => {
      wrapper = createComponent({}, { name: 'treePathDecoded', params: { path: 'project' } });
    });

    describe('PageHeading', () => {
      it('displays correct directory name', () => {
        expect(findPageHeading().text()).toContain('project');
        expect(findFileIcon().props('fileName')).toBe('folder-open');
        expect(findFileIcon().props('folder')).toBe(true);
        expect(findFileIcon().classes('gl-text-gray-700')).toBe(true);
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
      });
    });
  });

  describe('when rendered for tree view and directory_code_dropdown_updates flag is true', () => {
    it('renders CompactCodeDropdown with correct props', () => {
      wrapper = createComponent({}, {}, { glFeatures: { directoryCodeDropdownUpdates: true } });
      expect(findCompactCodeDropdown().exists()).toBe(true);
      expect(findCompactCodeDropdown().props()).toMatchObject({
        sshUrl: headerAppInjected.sshUrl,
        httpUrl: headerAppInjected.httpUrl,
        kerberosUrl: headerAppInjected.kerberosUrl,
        xcodeUrl: headerAppInjected.xcodeUrl,
        currentPath: defaultMockRoute.params.path,
        directoryDownloadLinks: headerAppInjected.downloadLinks,
      });
    });

    describe('RepositoryOverflowMenu', () => {
      it('does not render RepositoryOverflowMenu component on default ref', () => {
        expect(findRepositoryOverflowMenu().exists()).toBe(false);
      });

      it('renders RepositoryOverflowMenu component with correct props when on ref different than default branch', () => {
        wrapper = createComponent({}, 'treePathDecoded', { comparePath: 'test/project/compare' });
        expect(findRepositoryOverflowMenu().exists()).toBe(true);
        expect(findRepositoryOverflowMenu().props('comparePath')).toBe(
          headerAppInjected.comparePath,
        );
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

    it('displays correct file name and icon', () => {
      expect(findPageHeading().text()).toContain('index.js');
      expect(findFileIcon().props('fileName')).toBe('index.js');
      expect(findFileIcon().props('folder')).toBe(false);
      expect(findFileIcon().classes('gl-text-gray-700')).toBe(false);
    });
  });

  describe('when rendered for readme project overview', () => {
    beforeEach(() => {
      wrapper = createComponent({}, { name: 'treePathDecoded' }, { isReadmeView: true });
    });

    it('does not render directory name and icon', () => {
      expect(findPageHeading().exists()).toBe(false);
      expect(findFileIcon().exists()).toBe(false);
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

  describe('when rendered for full project overview', () => {
    beforeEach(() => {
      wrapper = createComponent({}, { name: 'projectRoot' });
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
