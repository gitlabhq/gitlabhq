import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import EditButton from '~/diffs/components/edit_button.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import diffDiscussionsMockData from '../mock_data/diff_discussions';
import { truncateSha } from '~/lib/utils/text_utility';
import { diffViewerModes } from '~/ide/constants';
import { __, sprintf } from '~/locale';
import { scrollToElement } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils');

const diffFile = Object.freeze(
  Object.assign(diffDiscussionsMockData.diff_file, {
    edit_path: 'link:/to/edit/path',
    blob: {
      id: '848ed9407c6730ff16edb3dd24485a0eea24292a',
      path: 'lib/base.js',
      name: 'base.js',
      mode: '100644',
      readable_text: true,
      icon: 'file-text-o',
    },
  }),
);

describe('DiffFileHeader component', () => {
  let wrapper;

  const diffHasExpandedDiscussionsResultMock = jest.fn();
  const diffHasDiscussionsResultMock = jest.fn();
  const mockStoreConfig = {
    state: {},
    modules: {
      diffs: {
        namespaced: true,
        getters: {
          diffHasExpandedDiscussions: () => diffHasExpandedDiscussionsResultMock,
          diffHasDiscussions: () => diffHasDiscussionsResultMock,
        },
        actions: {
          toggleFileDiscussions: jest.fn(),
          toggleFileDiscussionWrappers: jest.fn(),
          toggleFullDiff: jest.fn(),
        },
      },
    },
  };

  afterEach(() => {
    [
      diffHasDiscussionsResultMock,
      diffHasExpandedDiscussionsResultMock,
      ...Object.values(mockStoreConfig.modules.diffs.actions),
    ].forEach(mock => mock.mockReset());
  });

  const findHeader = () => wrapper.find({ ref: 'header' });
  const findTitleLink = () => wrapper.find({ ref: 'titleWrapper' });
  const findExpandButton = () => wrapper.find({ ref: 'expandDiffToFullFileButton' });
  const findFileActions = () => wrapper.find('.file-actions');
  const findModeChangedLine = () => wrapper.find({ ref: 'fileMode' });
  const findLfsLabel = () => wrapper.find('.label-lfs');
  const findToggleDiscussionsButton = () => wrapper.find({ ref: 'toggleDiscussionsButton' });
  const findExternalLink = () => wrapper.find({ ref: 'externalLink' });
  const findReplacedFileButton = () => wrapper.find({ ref: 'replacedFileButton' });
  const findViewFileButton = () => wrapper.find({ ref: 'viewButton' });
  const findCollapseIcon = () => wrapper.find({ ref: 'collapseIcon' });

  const findIconByName = iconName => {
    const icons = wrapper.findAll(Icon).filter(w => w.props('name') === iconName);
    if (icons.length === 0) return icons;
    if (icons.length > 1) {
      throw new Error(`Multiple icons found for ${iconName}`);
    }
    return icons.at(0);
  };

  const createComponent = props => {
    const localVue = createLocalVue();
    localVue.use(Vuex);
    const store = new Vuex.Store(mockStoreConfig);

    wrapper = shallowMount(DiffFileHeader, {
      propsData: {
        diffFile,
        canCurrentUserFork: false,
        ...props,
      },
      localVue,
      store,
      sync: false,
      attachToDocument: true,
    });
  };

  it.each`
    visibility   | collapsible
    ${'visible'} | ${true}
    ${'hidden'}  | ${false}
  `('collapse toggle is $visibility if collapsible is $collapsible', ({ collapsible }) => {
    createComponent({ collapsible });
    expect(findCollapseIcon().exists()).toBe(collapsible);
  });

  it.each`
    expanded | icon
    ${true}  | ${'chevron-down'}
    ${false} | ${'chevron-right'}
  `('collapse icon is $icon if expanded is $expanded', ({ icon, expanded }) => {
    createComponent({ expanded, collapsible: true });
    expect(findCollapseIcon().props('name')).toBe(icon);
  });

  it('when header is clicked emits toggleFile', () => {
    createComponent();
    findHeader().trigger('click');
    expect(wrapper.emitted().toggleFile).toBeDefined();
  });

  it('when collapseIcon is clicked emits toggleFile', () => {
    createComponent({ collapsible: true });
    findCollapseIcon().vm.$emit('click', new Event('click'));
    expect(wrapper.emitted().toggleFile).toBeDefined();
  });

  it('when other element in header is clicked does not emits toggleFile', () => {
    createComponent({ collapsible: true });
    findTitleLink().trigger('click');
    expect(wrapper.emitted().toggleFile).not.toBeDefined();
  });

  it('displays a copy to clipboard button', () => {
    createComponent();
    expect(wrapper.find(ClipboardButton).exists()).toBe(true);
  });

  describe('for submodule', () => {
    const submoduleDiffFile = {
      ...diffFile,
      submodule: true,
      submodule_link: 'link://to/submodule',
    };

    it('prefers submodule_tree_url over submodule_link for href', () => {
      const submoduleTreeUrl = 'some://tree/url';
      createComponent({
        discussionLink: 'discussionLink',
        diffFile: {
          ...submoduleDiffFile,
          submodule_tree_url: 'some://tree/url',
        },
      });

      expect(findTitleLink().attributes('href')).toBe(submoduleTreeUrl);
    });

    it('uses submodule_link for href if submodule_tree_url does not exists', () => {
      const submoduleLink = 'link://to/submodule';
      createComponent({
        discussionLink: 'discussionLink',
        diffFile: submoduleDiffFile,
      });

      expect(findTitleLink().attributes('href')).toBe(submoduleLink);
    });

    it('uses file_path + SHA as link text', () => {
      createComponent({
        diffFile: submoduleDiffFile,
      });

      expect(findTitleLink().text()).toContain(
        `${diffFile.file_path} @ ${truncateSha(diffFile.blob.id)}`,
      );
    });

    it('does not render file actions', () => {
      createComponent({
        diffFile: submoduleDiffFile,
        addMergeRequestButtons: true,
      });
      expect(findFileActions().exists()).toBe(false);
    });
  });

  describe('for any file', () => {
    const otherModes = Object.keys(diffViewerModes).filter(m => m !== 'mode_changed');

    it('when edit button emits showForkMessage event it is re-emitted', () => {
      createComponent({
        addMergeRequestButtons: true,
      });
      wrapper.find(EditButton).vm.$emit('showForkMessage');
      expect(wrapper.emitted().showForkMessage).toBeDefined();
    });

    it('for mode_changed file mode displays mode changes', () => {
      createComponent({
        diffFile: {
          ...diffFile,
          a_mode: 'old-mode',
          b_mode: 'new-mode',
          viewer: {
            ...diffFile.viewer,
            name: diffViewerModes.mode_changed,
          },
        },
      });
      expect(findModeChangedLine().text()).toMatch(/old-mode.+new-mode/);
    });

    it.each(otherModes.map(m => [m]))('for %s file mode does not display mode changes', mode => {
      createComponent({
        diffFile: {
          ...diffFile,
          a_mode: 'old-mode',
          b_mode: 'new-mode',
          viewer: {
            ...diffFile.viewer,
            name: diffViewerModes[mode],
          },
        },
      });
      expect(findModeChangedLine().exists()).toBeFalsy();
    });

    it('displays the LFS label for files stored in LFS', () => {
      createComponent({
        diffFile: { ...diffFile, stored_externally: true, external_storage: 'lfs' },
      });
      expect(findLfsLabel().exists()).toBe(true);
    });

    it('does not display the LFS label for files stored in repository', () => {
      createComponent({
        diffFile: { ...diffFile, stored_externally: false },
      });
      expect(findLfsLabel().exists()).toBe(false);
    });

    it('does not render view replaced file button if no replaced view path is present', () => {
      createComponent({
        diffFile: { ...diffFile, replaced_view_path: null },
      });
      expect(findReplacedFileButton().exists()).toBe(false);
    });

    describe('when addMergeRequestButtons is false', () => {
      it('does not render file actions', () => {
        createComponent({ addMergeRequestButtons: false });
        expect(findFileActions().exists()).toBe(false);
      });
      it('should not render edit button', () => {
        createComponent({ addMergeRequestButtons: false });
        expect(wrapper.find(EditButton).exists()).toBe(false);
      });
    });

    describe('when addMergeRequestButtons is true', () => {
      describe('without discussions', () => {
        it('renders a disabled toggle discussions button', () => {
          diffHasDiscussionsResultMock.mockReturnValue(false);
          createComponent({ addMergeRequestButtons: true });
          expect(findToggleDiscussionsButton().attributes('disabled')).toBe('true');
        });
      });

      describe('with discussions', () => {
        it('dispatches toggleFileDiscussionWrappers when user clicks on toggle discussions button', () => {
          diffHasDiscussionsResultMock.mockReturnValue(true);
          createComponent({ addMergeRequestButtons: true });
          expect(findToggleDiscussionsButton().attributes('disabled')).toBeFalsy();
          findToggleDiscussionsButton().vm.$emit('click');
          expect(
            mockStoreConfig.modules.diffs.actions.toggleFileDiscussionWrappers,
          ).toHaveBeenCalledWith(expect.any(Object), diffFile, undefined);
        });
      });

      it('should show edit button', () => {
        createComponent({
          addMergeRequestButtons: true,
        });
        expect(wrapper.find(EditButton).exists()).toBe(true);
      });

      describe('view on environment button', () => {
        it('is displayed when external url is provided', () => {
          const externalUrl = 'link://to/external';
          const formattedExternalUrl = 'link://formatted';
          createComponent({
            diffFile: {
              ...diffFile,
              external_url: externalUrl,
              formatted_external_url: formattedExternalUrl,
            },
            addMergeRequestButtons: true,
          });
          expect(findExternalLink().exists()).toBe(true);
        });

        it('is hidden by default', () => {
          createComponent({ addMergeRequestButtons: true });
          expect(findExternalLink().exists()).toBe(false);
        });
      });

      describe('without file blob', () => {
        beforeEach(() => {
          createComponent({ diffFile: { ...diffFile, blob: false } });
        });

        it('should not render toggle discussions button', () => {
          expect(findToggleDiscussionsButton().exists()).toBe(false);
        });

        it('should not render edit button', () => {
          expect(wrapper.find(EditButton).exists()).toBe(false);
        });
      });
      describe('with file blob', () => {
        it('should render correct file view button', () => {
          const viewPath = 'link://view-path';
          createComponent({
            diffFile: { ...diffFile, view_path: viewPath },
            addMergeRequestButtons: true,
          });
          expect(findViewFileButton().attributes('href')).toBe(viewPath);
          expect(findViewFileButton().attributes('data-original-title')).toEqual(
            `View file @ ${diffFile.content_sha.substr(0, 8)}`,
          );
        });
      });
    });

    describe('expand full file button', () => {
      describe('when diff is fully expanded', () => {
        it('is not rendered', () => {
          createComponent({
            diffFile: {
              ...diffFile,
              is_fully_expanded: true,
            },
          });
          expect(findExpandButton().exists()).toBe(false);
        });
      });
      describe('when diff is not fully expanded', () => {
        const fullyNotExpandedFileProps = {
          diffFile: {
            ...diffFile,
            is_fully_expanded: false,
            edit_path: 'link/to/edit/path.txt',
            isShowingFullFile: false,
          },
          addMergeRequestButtons: true,
        };

        it.each`
          iconName         | isShowingFullFile
          ${'doc-expand'}  | ${false}
          ${'doc-changes'} | ${true}
        `(
          'shows $iconName when isShowingFullFile set to $isShowingFullFile',
          ({ iconName, isShowingFullFile }) => {
            createComponent({
              ...fullyNotExpandedFileProps,
              diffFile: { ...fullyNotExpandedFileProps.diffFile, isShowingFullFile },
            });
            expect(findIconByName(iconName).exists()).toBe(true);
          },
        );

        it('renders expand to full file button if not showing full file already', () => {
          createComponent(fullyNotExpandedFileProps);
          expect(findExpandButton().exists()).toBe(true);
        });

        it('renders loading icon when loading full file', () => {
          createComponent(fullyNotExpandedFileProps);
          expect(findExpandButton().exists()).toBe(true);
        });

        it('toggles full diff on click', () => {
          createComponent(fullyNotExpandedFileProps);
          findExpandButton().vm.$emit('click');
          expect(mockStoreConfig.modules.diffs.actions.toggleFullDiff).toHaveBeenCalled();
        });
      });
    });

    it('uses discussionPath for link if it is defined', () => {
      const discussionPath = 'link://to/discussion';
      createComponent({
        discussionPath,
      });
      expect(findTitleLink().attributes('href')).toBe(discussionPath);
    });

    it('uses local anchor for link as last resort', () => {
      createComponent();
      expect(findTitleLink().attributes('href')).toMatch(/^#diff-content/);
    });

    describe('when local anchor for link is clicked', () => {
      beforeEach(() => {
        createComponent();
      });

      it('scrolls to target', () => {
        findTitleLink().trigger('click');
        expect(scrollToElement).toHaveBeenCalled();
      });

      it('updates anchor in URL', () => {
        findTitleLink().trigger('click');
        expect(window.location.href).toMatch(/#diff-content/);
      });
    });
  });

  describe('for new file', () => {
    it('displays the path', () => {
      createComponent({ diffFile: { ...diffFile, new_file: true } });
      expect(findTitleLink().text()).toBe(diffFile.file_path);
    });
  });

  describe('for deleted file', () => {
    it('displays the path', () => {
      createComponent({ diffFile: { ...diffFile, deleted_file: true } });
      expect(findTitleLink().text()).toBe(
        sprintf(__('%{filePath} deleted'), { filePath: diffFile.file_path }, false),
      );
    });

    it('does not show edit button', () => {
      createComponent({ diffFile: { ...diffFile, deleted_file: true } });
      expect(wrapper.find(EditButton).exists()).toBe(false);
    });
  });

  describe('for renamed file', () => {
    it('displays old and new path if the file was renamed', () => {
      createComponent({
        diffFile: {
          ...diffFile,
          renamed_file: true,
          old_path_html: 'old',
          new_path_html: 'new',
        },
      });
      expect(findTitleLink().text()).toMatch(/^old.+new/s);
    });
  });

  describe('for replaced file', () => {
    it('renders view replaced file button', () => {
      const replacedViewPath = 'some/path';
      createComponent({
        diffFile: {
          ...diffFile,
          replaced_view_path: replacedViewPath,
        },
        addMergeRequestButtons: true,
      });
      expect(findReplacedFileButton().exists()).toBe(true);
    });
  });
});
