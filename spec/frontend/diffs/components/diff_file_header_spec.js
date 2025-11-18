import { GlAnimatedChevronRightDownIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, triggerEvent } from 'helpers/tracking_helper';
import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import { DIFF_FILE_AUTOMATIC_COLLAPSE, DIFF_FILE_MANUAL_COLLAPSE } from '~/diffs/constants';
import { diffViewerModes } from '~/ide/constants';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useNotes } from '~/notes/store/legacy_notes';
import diffsEventHub from '~/diffs/event_hub';
import diffDiscussionsMockData from '../mock_data/diff_discussions';

jest.mock('~/lib/utils/common_utils', () => ({
  convertObjectPropsToCamelCase: jest.requireActual('~/lib/utils/common_utils')
    .convertObjectPropsToCamelCase,
  isInMRPage: jest.requireActual('~/lib/utils/common_utils').isInMRPage,
  isLoggedIn: () => true,
}));
jest.mock('~/lib/utils/scroll_utils');
jest.mock('~/diffs/event_hub');

const createDiffFile = () => ({
  ...diffDiscussionsMockData.diff_file,
  highlighted_diff_lines: [
    ...diffDiscussionsMockData.diff_file.highlighted_diff_lines.map((line) => {
      return { ...line, discussions: [] };
    }),
  ],
  id: '123',
  file_hash: 'xyz',
  file_identifier_hash: 'abc',
  edit_path: 'link:/to/edit/path',
  blob: {
    id: '848ed9407c6730ff16edb3dd24485a0eea24292a',
    path: 'lib/base.js',
    name: 'base.js',
    mode: '100644',
    readable_text: true,
    icon: 'doc-text',
  },
});

Vue.use(PiniaVuePlugin);

describe('DiffFileHeader component', () => {
  let wrapper;
  let pinia;

  const getFirstDiffFile = () => useLegacyDiffs().diffFiles[0];
  const findHeader = () => wrapper.findComponent({ ref: 'header' });
  const findTitleLink = () => wrapper.findByTestId('file-title');
  const findExpandButton = () => wrapper.findComponent({ ref: 'expandDiffToFullFileButton' });
  const findFileActions = () => wrapper.find('.file-actions');
  const findModeChangedLine = () => wrapper.findComponent({ ref: 'fileMode' });
  const findLfsLabel = () => wrapper.find('[data-testid="label-lfs"]');
  const findToggleDiscussionsButton = () =>
    wrapper.findComponent({ ref: 'toggleDiscussionsButton' });
  const findExternalLink = () => wrapper.findComponent({ ref: 'externalLink' });
  const findReplacedFileButton = () => wrapper.findComponent({ ref: 'replacedFileButton' });
  const findViewFileButton = () => wrapper.findComponent({ ref: 'viewButton' });
  const findCollapseButton = () => wrapper.findComponent({ ref: 'collapseButton' });
  // In Vue3 this is kebabbed, in Vue2 it is not
  const findCollapseIconIsOn = () =>
    wrapper.findComponent(GlAnimatedChevronRightDownIcon).attributes('is-on') ||
    wrapper.findComponent(GlAnimatedChevronRightDownIcon).attributes('ison');
  const findEditButton = () => wrapper.findComponent({ ref: 'editButton' });
  const findReviewFileCheckbox = () => wrapper.find("[data-testid='fileReviewCheckbox']");

  const createComponent = ({ props, options = {} } = {}) => {
    wrapper = shallowMountExtended(DiffFileHeader, {
      propsData: {
        diffFile: getFirstDiffFile(),
        canCurrentUserFork: false,
        viewDiffsFileByFile: false,
        ...props,
      },
      ...options,
      pinia,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs().diffFiles = [createDiffFile()];
    useNotes();
  });

  it.each`
    visibility   | collapsible
    ${'visible'} | ${true}
    ${'hidden'}  | ${false}
  `('collapse toggle is $visibility if collapsible is $collapsible', ({ collapsible }) => {
    createComponent({ props: { collapsible } });
    expect(findCollapseButton().exists()).toBe(collapsible);
  });

  it('GlAnimatedChevronRightDownIcon isOn prop is true if expanded', () => {
    createComponent({ props: { expanded: true, collapsible: true } });

    expect(findCollapseIconIsOn()).toBe('true');
  });

  it('GlAnimatedChevronRightDownIcon isOn prop is false if collapsed', () => {
    createComponent({ props: { expanded: false, collapsible: true } });

    expect(findCollapseIconIsOn()).toBeUndefined();
  });

  it('when header is clicked emits toggleFile', async () => {
    createComponent();
    findHeader().trigger('click');

    await nextTick();
    expect(wrapper.emitted().toggleFile).toBeDefined();
  });

  it('when header is clicked it emits setFileActive', async () => {
    createComponent();
    findHeader().trigger('click');

    await nextTick();

    expect(diffsEventHub.$emit).toHaveBeenCalledWith('setFileActive', 'xyz');
  });

  it('when header is clicked it triggers the action that removes the value that forces a file to be uncollapsed', () => {
    createComponent();
    findHeader().trigger('click');

    expect(useLegacyDiffs().setFileForcedOpen).toHaveBeenCalledWith({
      filePath: getFirstDiffFile().file_path,
      forced: false,
    });
  });

  it('when collapseIcon is clicked emits toggleFile', async () => {
    createComponent({ props: { collapsible: true } });
    findCollapseButton().vm.$emit('click', new Event('click'));
    await nextTick();
    expect(wrapper.emitted().toggleFile).toBeDefined();
  });

  it('when other element in header is clicked does not emits toggleFile', async () => {
    createComponent({ props: { collapsible: true } });
    findTitleLink().trigger('click');

    await nextTick();
    expect(wrapper.emitted().toggleFile).not.toBeDefined();
  });

  describe('copy to clipboard', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays a copy to clipboard button', () => {
      expect(wrapper.findComponent(ClipboardButton).exists()).toBe(true);
    });

    it('triggers the copy to clipboard tracking event', () => {
      const trackingSpy = mockTracking('_category_', wrapper.vm.$el, jest.spyOn);

      triggerEvent('[data-testid="diff-file-copy-clipboard"]');

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_copy_file_button', {
        label: 'diff_copy_file_path_button',
        property: 'diff_copy_file',
      });
    });
  });

  describe('for submodule', () => {
    const submoduleDiffFile = {
      ...createDiffFile(),
      submodule: true,
      submodule_link: 'link://to/submodule',
    };

    it('prefers submodule_tree_url over submodule_link for href', () => {
      const submoduleTreeUrl = 'some://tree/url';
      createComponent({
        props: {
          discussionLink: 'discussionLink',
          diffFile: {
            ...submoduleDiffFile,
            submodule_tree_url: 'some://tree/url',
          },
        },
      });

      expect(findTitleLink().attributes('href')).toBe(submoduleTreeUrl);
    });

    it('uses submodule_link for href if submodule_tree_url does not exists', () => {
      const submoduleLink = 'link://to/submodule';
      createComponent({
        props: {
          discussionLink: 'discussionLink',
          diffFile: submoduleDiffFile,
        },
      });

      expect(findTitleLink().attributes('href')).toBe(submoduleLink);
    });

    it('uses file_path + SHA as link text', () => {
      createComponent({
        props: {
          diffFile: submoduleDiffFile,
        },
      });

      expect(findTitleLink().text()).toContain(
        `${getFirstDiffFile().file_path} @ ${truncateSha(getFirstDiffFile().blob.id)}`,
      );
    });

    it('does not render file actions', () => {
      createComponent({
        props: {
          diffFile: submoduleDiffFile,
          addMergeRequestButtons: true,
        },
      });
      expect(findFileActions().exists()).toBe(false);
    });
  });

  describe('for any file', () => {
    const allModes = Object.keys(diffViewerModes).map((m) => [m]);

    it.each(allModes)('for %s file mode displays mode changes', (mode) => {
      createComponent({
        props: {
          diffFile: {
            ...createDiffFile(),
            mode_changed: true,
            a_mode: 'old-mode',
            b_mode: 'new-mode',
            viewer: {
              ...createDiffFile().viewer,
              name: diffViewerModes[mode],
            },
          },
        },
      });
      expect(findModeChangedLine().text()).toMatch(/old-mode.+new-mode/);
    });

    it.each(allModes.filter((m) => m[0] !== 'mode_changed'))(
      'for %s file mode does not display mode changes',
      (mode) => {
        createComponent({
          props: {
            diffFile: {
              ...createDiffFile(),
              mode_changed: false,
              a_mode: 'old-mode',
              b_mode: 'new-mode',
              viewer: {
                ...createDiffFile().viewer,
                name: diffViewerModes[mode],
              },
            },
          },
        });
        expect(findModeChangedLine().exists()).toBe(false);
      },
    );

    it('displays the LFS label for files stored in LFS', () => {
      createComponent({
        props: {
          diffFile: { ...createDiffFile(), stored_externally: true, external_storage: 'lfs' },
        },
      });
      expect(findLfsLabel().exists()).toBe(true);
    });

    it('does not display the LFS label for files stored in repository', () => {
      createComponent({
        props: {
          diffFile: { ...createDiffFile(), stored_externally: false },
        },
      });
      expect(findLfsLabel().exists()).toBe(false);
    });

    it('does not render view replaced file button if no replaced view path is present', () => {
      createComponent({
        props: {
          diffFile: { ...createDiffFile(), replaced_view_path: null },
        },
      });
      expect(findReplacedFileButton().exists()).toBe(false);
    });

    describe('when addMergeRequestButtons is false', () => {
      it('does not render file actions', () => {
        createComponent({ props: { addMergeRequestButtons: false } });
        expect(findFileActions().exists()).toBe(false);
      });
      it('should not render edit button', () => {
        createComponent({ props: { addMergeRequestButtons: false } });
        expect(findEditButton().exists()).toBe(false);
      });
    });

    describe('when addMergeRequestButtons is true', () => {
      describe('without discussions', () => {
        it('does not render a toggle discussions button', () => {
          createComponent({ props: { addMergeRequestButtons: true } });
          expect(findToggleDiscussionsButton().exists()).toBe(false);
        });
      });

      describe('with discussions', () => {
        let diffFile;

        beforeEach(() => {
          diffFile = createDiffFile();
          diffFile.highlighted_diff_lines[0].discussions = [{}];
          useLegacyDiffs().diffFiles = [diffFile];
        });

        it('dispatches toggleFileDiscussionWrappers when user clicks on toggle discussions button', () => {
          createComponent({ props: { diffFile, addMergeRequestButtons: true } });
          expect(findToggleDiscussionsButton().exists()).toBe(true);
          findToggleDiscussionsButton().props('item').action();
          expect(useLegacyDiffs().toggleFileDiscussionWrappers).toHaveBeenCalledWith(
            getFirstDiffFile(),
          );
        });
      });

      it('should show edit button', () => {
        createComponent({
          props: {
            addMergeRequestButtons: true,
          },
        });
        expect(findEditButton().exists()).toBe(true);
      });

      describe('view on environment button', () => {
        it('is displayed when external url is provided', () => {
          const externalUrl = 'link://to/external';
          const formattedExternalUrl = 'link://formatted';
          createComponent({
            props: {
              diffFile: {
                ...createDiffFile(),
                external_url: externalUrl,
                formatted_external_url: formattedExternalUrl,
              },
              addMergeRequestButtons: true,
            },
          });
          expect(findExternalLink().exists()).toBe(true);
        });

        it('is hidden by default', () => {
          createComponent({ props: { addMergeRequestButtons: true } });
          expect(findExternalLink().exists()).toBe(false);
        });
      });

      describe('without file blob', () => {
        beforeEach(() => {
          createComponent({ props: { diffFile: { ...createDiffFile(), blob: false } } });
        });

        it('should not render toggle discussions button', () => {
          expect(findToggleDiscussionsButton().exists()).toBe(false);
        });

        it('should not render edit button', () => {
          expect(findEditButton().exists()).toBe(false);
        });
      });
      describe('with file blob', () => {
        it('should render correct file view button', () => {
          const viewPath = 'link://view-path';
          createComponent({
            props: {
              diffFile: { ...createDiffFile(), view_path: viewPath },
              addMergeRequestButtons: true,
            },
          });
          expect(findViewFileButton().props('item').href).toBe(viewPath);
          expect(findViewFileButton().props('item').text).toEqual(
            `View file @ ${getFirstDiffFile().content_sha.substr(0, 8)}`,
          );
        });
      });
    });

    describe('expand full file button', () => {
      describe('when diff is fully expanded', () => {
        it('is not rendered', () => {
          createComponent({
            props: {
              diffFile: {
                ...createDiffFile(),
                is_fully_expanded: true,
              },
            },
          });
          expect(findExpandButton().exists()).toBe(false);
        });
      });
      describe('when diff is not fully expanded', () => {
        const fullyNotExpandedFileProps = {
          diffFile: {
            ...createDiffFile(),
            is_fully_expanded: false,
            edit_path: 'link/to/edit/path.txt',
            isShowingFullFile: false,
          },
          addMergeRequestButtons: true,
        };

        it('renders expand to full file button if not showing full file already', () => {
          createComponent({ props: fullyNotExpandedFileProps });
          expect(findExpandButton().exists()).toBe(true);
        });

        it('renders loading icon when loading full file', () => {
          createComponent({ props: fullyNotExpandedFileProps });
          expect(findExpandButton().exists()).toBe(true);
        });

        it('toggles full diff on click', () => {
          createComponent({ props: fullyNotExpandedFileProps });
          findExpandButton().props('item').action();
          expect(useLegacyDiffs().toggleFullDiff).toHaveBeenCalledWith(
            fullyNotExpandedFileProps.diffFile.file_path,
          );
        });
      });
    });

    it('uses discussionPath for link if it is defined', () => {
      const discussionPath = 'link://to/discussion';
      createComponent({
        props: {
          discussionPath,
        },
      });
      expect(findTitleLink().attributes('href')).toBe(discussionPath);
    });

    it('uses local anchor for link as last resort', () => {
      createComponent();
      expect(findTitleLink().attributes('href')).toMatch(
        new RegExp(`#diff-content-${getFirstDiffFile().file_hash}$`),
      );
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
      createComponent({ props: { diffFile: { ...createDiffFile(), new_file: true } } });
      expect(findTitleLink().text()).toBe(getFirstDiffFile().file_path);
    });
  });

  describe('for deleted file', () => {
    it('displays the path', () => {
      createComponent({ props: { diffFile: { ...createDiffFile(), deleted_file: true } } });
      expect(findTitleLink().text()).toBe(
        sprintf('%{filePath} deleted', { filePath: getFirstDiffFile().file_path }, false),
      );
    });

    it('does not show edit button', () => {
      createComponent({ props: { diffFile: { ...createDiffFile(), deleted_file: true } } });
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('for renamed file', () => {
    it('displays old and new path if the file was renamed', () => {
      createComponent({
        props: {
          diffFile: {
            ...createDiffFile(),
            renamed_file: true,
            old_path_html: 'old',
            new_path_html: 'new',
          },
        },
      });
      expect(findTitleLink().text()).toMatch(/^old.+new/s);
    });
  });

  describe('for replaced file', () => {
    it('renders view replaced file button', () => {
      const replacedViewPath = 'some/path';
      createComponent({
        props: {
          diffFile: {
            ...createDiffFile(),
            replaced_view_path: replacedViewPath,
          },
          addMergeRequestButtons: true,
        },
      });
      expect(findReplacedFileButton().exists()).toBe(true);
    });
  });

  describe('file reviews', () => {
    it('calls the action to set the new review', () => {
      jest.spyOn(document.activeElement, 'blur');
      createComponent({
        props: {
          diffFile: {
            ...createDiffFile(),
            viewer: {
              ...createDiffFile().viewer,
              automaticallyCollapsed: false,
              manuallyCollapsed: null,
            },
          },
          showLocalFileReviews: true,
          addMergeRequestButtons: true,
        },
      });

      const file = wrapper.vm.diffFile;

      findReviewFileCheckbox().vm.$emit('change', true);

      expect(document.activeElement.blur).toHaveBeenCalled();

      expect(useLegacyDiffs().reviewFile).toHaveBeenCalledWith({ file, reviewed: true });
    });

    it.each`
      description             | newReviewedStatus | collapseType                    | aCollapse | mCollapse | callAction
      ${'does nothing'}       | ${true}           | ${DIFF_FILE_MANUAL_COLLAPSE}    | ${false}  | ${true}   | ${false}
      ${'does nothing'}       | ${false}          | ${DIFF_FILE_AUTOMATIC_COLLAPSE} | ${true}   | ${null}   | ${false}
      ${'does nothing'}       | ${true}           | ${'not collapsed'}              | ${false}  | ${null}   | ${false}
      ${'does nothing'}       | ${false}          | ${'not collapsed'}              | ${false}  | ${null}   | ${false}
      ${'collapses the file'} | ${true}           | ${DIFF_FILE_AUTOMATIC_COLLAPSE} | ${true}   | ${null}   | ${true}
    `(
      "$description if the new review status is reviewed = $newReviewedStatus and the file's collapse type is collapse = $collapseType",
      ({ newReviewedStatus, aCollapse, mCollapse, callAction }) => {
        createComponent({
          props: {
            diffFile: {
              ...createDiffFile(),
              viewer: {
                ...createDiffFile().viewer,
                automaticallyCollapsed: aCollapse,
                manuallyCollapsed: mCollapse,
              },
            },
            showLocalFileReviews: true,
            addMergeRequestButtons: true,
          },
        });

        findReviewFileCheckbox().vm.$emit('change', newReviewedStatus);

        if (callAction) {
          expect(useLegacyDiffs().setFileCollapsedByUser).toHaveBeenCalled();
        } else {
          expect(useLegacyDiffs().setFileCollapsedByUser).not.toHaveBeenCalled();
        }
      },
    );

    it.each`
      description | show     | visible
      ${'shows'}  | ${true}  | ${true}
      ${'hides'}  | ${false} | ${false}
    `(
      '$description the file review feature given { showLocalFileReviewsProp: $show }',
      ({ show, visible }) => {
        createComponent({
          props: {
            showLocalFileReviews: show,
            addMergeRequestButtons: true,
          },
        });

        expect(findReviewFileCheckbox().exists()).toEqual(visible);
      },
    );

    it.each`
      open     | status   | fires
      ${true}  | ${true}  | ${true}
      ${false} | ${false} | ${true}
      ${true}  | ${false} | ${false}
      ${false} | ${true}  | ${false}
    `(
      'toggles appropriately when { fileExpanded: $open, newReviewStatus: $status }',
      ({ open, status, fires }) => {
        createComponent({
          props: {
            diffFile: {
              ...createDiffFile(),
              viewer: {
                ...createDiffFile().viewer,
                automaticallyCollapsed: false,
                manuallyCollapsed: null,
              },
            },
            showLocalFileReviews: true,
            addMergeRequestButtons: true,
            expanded: open,
          },
        });

        findReviewFileCheckbox().vm.$emit('change', status);

        expect(Boolean(wrapper.emitted().toggleFile)).toBe(fires);
      },
    );

    it('removes the property that forces a file to be shown when the file review is toggled', () => {
      createComponent({
        props: {
          diffFile: {
            ...createDiffFile(),
            viewer: {
              ...createDiffFile().viewer,
              automaticallyCollapsed: false,
              manuallyCollapsed: null,
            },
          },
          showLocalFileReviews: true,
          addMergeRequestButtons: true,
          expanded: false,
        },
      });

      findReviewFileCheckbox().vm.$emit('change', true);
      findReviewFileCheckbox().vm.$emit('change', false);

      expect(useLegacyDiffs().setFileForcedOpen).toHaveBeenCalledWith({
        filePath: getFirstDiffFile().file_path,
        forced: false,
      });
    });
  });

  it('should render the comment on files button', () => {
    window.gon = { current_user_id: 1 };
    useNotes().noteableData.current_user = { can_create_note: true };
    createComponent({
      props: {
        addMergeRequestButtons: true,
      },
    });

    expect(wrapper.find('[data-testid="comment-files-button"]').exists()).toEqual(true);
  });
});
