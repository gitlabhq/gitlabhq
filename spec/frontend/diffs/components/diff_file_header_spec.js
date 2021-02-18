import { shallowMount, createLocalVue } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vuex from 'vuex';

import { mockTracking, triggerEvent } from 'helpers/tracking_helper';

import DiffFileHeader from '~/diffs/components/diff_file_header.vue';
import { DIFF_FILE_AUTOMATIC_COLLAPSE, DIFF_FILE_MANUAL_COLLAPSE } from '~/diffs/constants';
import { reviewFile } from '~/diffs/store/actions';
import { SET_MR_FILE_REVIEWS } from '~/diffs/store/mutation_types';
import { diffViewerModes } from '~/ide/constants';
import { scrollToElement } from '~/lib/utils/common_utils';
import { truncateSha } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';

import testAction from '../../__helpers__/vuex_action_helper';
import diffDiscussionsMockData from '../mock_data/diff_discussions';

jest.mock('~/lib/utils/common_utils');

const diffFile = Object.freeze(
  Object.assign(diffDiscussionsMockData.diff_file, {
    id: '123',
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
  }),
);

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DiffFileHeader component', () => {
  let wrapper;
  let mockStoreConfig;

  const diffHasExpandedDiscussionsResultMock = jest.fn();
  const diffHasDiscussionsResultMock = jest.fn();
  const defaultMockStoreConfig = {
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
          toggleActiveFileByHash: jest.fn(),
          setFileCollapsedByUser: jest.fn(),
          reviewFile: jest.fn(),
        },
      },
    },
  };

  afterEach(() => {
    [
      diffHasDiscussionsResultMock,
      diffHasExpandedDiscussionsResultMock,
      ...Object.values(mockStoreConfig.modules.diffs.actions),
    ].forEach((mock) => mock.mockReset());

    wrapper.destroy();
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
  const findEditButton = () => wrapper.find({ ref: 'editButton' });
  const findReviewFileCheckbox = () => wrapper.find("[data-testid='fileReviewCheckbox']");

  const createComponent = ({ props, options = {} } = {}) => {
    mockStoreConfig = cloneDeep(defaultMockStoreConfig);
    const store = new Vuex.Store({ ...mockStoreConfig, ...(options.store || {}) });

    wrapper = shallowMount(DiffFileHeader, {
      propsData: {
        diffFile,
        canCurrentUserFork: false,
        viewDiffsFileByFile: false,
        ...props,
      },
      ...options,
      localVue,
      store,
    });
  };

  it.each`
    visibility   | collapsible
    ${'visible'} | ${true}
    ${'hidden'}  | ${false}
  `('collapse toggle is $visibility if collapsible is $collapsible', ({ collapsible }) => {
    createComponent({ props: { collapsible } });
    expect(findCollapseIcon().exists()).toBe(collapsible);
  });

  it.each`
    expanded | icon
    ${true}  | ${'chevron-down'}
    ${false} | ${'chevron-right'}
  `('collapse icon is $icon if expanded is $expanded', ({ icon, expanded }) => {
    createComponent({ props: { expanded, collapsible: true } });
    expect(findCollapseIcon().props('name')).toBe(icon);
  });

  it('when header is clicked emits toggleFile', () => {
    createComponent();
    findHeader().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().toggleFile).toBeDefined();
    });
  });

  it('when collapseIcon is clicked emits toggleFile', () => {
    createComponent({ props: { collapsible: true } });
    findCollapseIcon().vm.$emit('click', new Event('click'));
    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().toggleFile).toBeDefined();
    });
  });

  it('when other element in header is clicked does not emits toggleFile', () => {
    createComponent({ props: { collapsible: true } });
    findTitleLink().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().toggleFile).not.toBeDefined();
    });
  });

  describe('copy to clipboard', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays a copy to clipboard button', () => {
      expect(wrapper.find(ClipboardButton).exists()).toBe(true);
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
      ...diffFile,
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
        `${diffFile.file_path} @ ${truncateSha(diffFile.blob.id)}`,
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

    it('renders submodule icon', () => {
      createComponent({
        props: {
          diffFile: submoduleDiffFile,
        },
      });

      expect(wrapper.find(FileIcon).props('submodule')).toBe(true);
    });
  });

  describe('for any file', () => {
    const otherModes = Object.keys(diffViewerModes).filter((m) => m !== 'mode_changed');

    it('for mode_changed file mode displays mode changes', () => {
      createComponent({
        props: {
          diffFile: {
            ...diffFile,
            a_mode: 'old-mode',
            b_mode: 'new-mode',
            viewer: {
              ...diffFile.viewer,
              name: diffViewerModes.mode_changed,
            },
          },
        },
      });
      expect(findModeChangedLine().text()).toMatch(/old-mode.+new-mode/);
    });

    it.each(otherModes.map((m) => [m]))(
      'for %s file mode does not display mode changes',
      (mode) => {
        createComponent({
          props: {
            diffFile: {
              ...diffFile,
              a_mode: 'old-mode',
              b_mode: 'new-mode',
              viewer: {
                ...diffFile.viewer,
                name: diffViewerModes[mode],
              },
            },
          },
        });
        expect(findModeChangedLine().exists()).toBeFalsy();
      },
    );

    it('displays the LFS label for files stored in LFS', () => {
      createComponent({
        props: {
          diffFile: { ...diffFile, stored_externally: true, external_storage: 'lfs' },
        },
      });
      expect(findLfsLabel().exists()).toBe(true);
    });

    it('does not display the LFS label for files stored in repository', () => {
      createComponent({
        props: {
          diffFile: { ...diffFile, stored_externally: false },
        },
      });
      expect(findLfsLabel().exists()).toBe(false);
    });

    it('does not render view replaced file button if no replaced view path is present', () => {
      createComponent({
        props: {
          diffFile: { ...diffFile, replaced_view_path: null },
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
          diffHasDiscussionsResultMock.mockReturnValue(false);
          createComponent({ props: { addMergeRequestButtons: true } });
          expect(findToggleDiscussionsButton().exists()).toBe(false);
        });
      });

      describe('with discussions', () => {
        it('dispatches toggleFileDiscussionWrappers when user clicks on toggle discussions button', () => {
          diffHasDiscussionsResultMock.mockReturnValue(true);
          createComponent({ props: { addMergeRequestButtons: true } });
          expect(findToggleDiscussionsButton().exists()).toBe(true);
          findToggleDiscussionsButton().vm.$emit('click');
          expect(
            mockStoreConfig.modules.diffs.actions.toggleFileDiscussionWrappers,
          ).toHaveBeenCalledWith(expect.any(Object), diffFile);
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
                ...diffFile,
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
          createComponent({ props: { diffFile: { ...diffFile, blob: false } } });
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
              diffFile: { ...diffFile, view_path: viewPath },
              addMergeRequestButtons: true,
            },
          });
          expect(findViewFileButton().attributes('href')).toBe(viewPath);
          expect(findViewFileButton().text()).toEqual(
            `View file @ ${diffFile.content_sha.substr(0, 8)}`,
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
                ...diffFile,
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
            ...diffFile,
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
          findExpandButton().vm.$emit('click');
          expect(mockStoreConfig.modules.diffs.actions.toggleFullDiff).toHaveBeenCalled();
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
      createComponent({ props: { diffFile: { ...diffFile, new_file: true } } });
      expect(findTitleLink().text()).toBe(diffFile.file_path);
    });
  });

  describe('for deleted file', () => {
    it('displays the path', () => {
      createComponent({ props: { diffFile: { ...diffFile, deleted_file: true } } });
      expect(findTitleLink().text()).toBe(
        sprintf(__('%{filePath} deleted'), { filePath: diffFile.file_path }, false),
      );
    });

    it('does not show edit button', () => {
      createComponent({ props: { diffFile: { ...diffFile, deleted_file: true } } });
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('for renamed file', () => {
    it('displays old and new path if the file was renamed', () => {
      createComponent({
        props: {
          diffFile: {
            ...diffFile,
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
            ...diffFile,
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
      createComponent({
        props: {
          diffFile: {
            ...diffFile,
            viewer: {
              ...diffFile.viewer,
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

      return testAction(
        reviewFile,
        { file, reviewed: true },
        {},
        [{ type: SET_MR_FILE_REVIEWS, payload: { [file.file_identifier_hash]: [file.id] } }],
        [],
      );
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
              ...diffFile,
              viewer: {
                ...diffFile.viewer,
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
          expect(mockStoreConfig.modules.diffs.actions.setFileCollapsedByUser).toHaveBeenCalled();
        } else {
          expect(
            mockStoreConfig.modules.diffs.actions.setFileCollapsedByUser,
          ).not.toHaveBeenCalled();
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
              ...diffFile,
              viewer: {
                ...diffFile.viewer,
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
  });
});
