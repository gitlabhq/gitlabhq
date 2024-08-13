import {
  GlAlert,
  GlDisclosureDropdown,
  GlFormCheckbox,
  GlLoadingIcon,
  GlModal,
  GlKeysetPagination,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { createAlert } from '~/alert';
import {
  packageFiles as packageFilesMock,
  packageFilesQuery,
  packageDestroyFilesMutation,
  packageDestroyFilesMutationError,
  pagination,
} from 'jest/packages_and_registries/package_registry/mock_data';
import {
  DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
  DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILES_ERROR_MESSAGE,
  GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
} from '~/packages_and_registries/package_registry/constants';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import getPackageFiles from '~/packages_and_registries/package_registry/graphql/queries/get_package_files.query.graphql';
import destroyPackageFilesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_files.mutation.graphql';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: jest.fn(),
}));

describe('Package Files', () => {
  let wrapper;
  let apolloProvider;

  const findAllRows = () => wrapper.findAllByTestId('file-row');
  const findDeleteSelectedButton = () => wrapper.findByTestId('delete-selected');
  const findDeleteFilesModal = () => wrapper.findByTestId('delete-files-modal');
  const findFirstRow = () => extendedWrapper(findAllRows().at(0));
  const findSecondRow = () => extendedWrapper(findAllRows().at(1));
  const findPackageFilesAlert = () => wrapper.findComponent(GlAlert);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findFirstRowDownloadLink = () => findFirstRow().findByTestId('download-link');
  const findFirstRowFileIcon = () => findFirstRow().findComponent(FileIcon);
  const findFirstRowCreatedAt = () => findFirstRow().findComponent(TimeAgoTooltip);
  const findFirstActionMenu = () =>
    extendedWrapper(findFirstRow().findComponent(GlDisclosureDropdown));
  const findActionMenuDelete = () => findFirstActionMenu().findByTestId('delete-file');
  const findFirstToggleDetailsButton = () => findFirstRow().findByTestId('toggle-details-button');
  const findFirstRowShaComponent = (id) => wrapper.findByTestId(id);
  const findCheckAllCheckbox = () => wrapper.findByTestId('package-files-checkbox-all');
  const findAllRowCheckboxes = () => wrapper.findAllByTestId('package-files-checkbox');

  const files = packageFilesMock();
  const [file] = files;

  const showMock = jest.fn();
  const eventCategory = 'UI::NpmPackages';

  const createComponent = ({
    packageId = '1',
    packageType = 'NPM',
    projectPath = 'gitlab-test',
    canDelete = true,
    deleteAllFiles = false,
    stubs,
    resolver = jest.fn().mockResolvedValue(packageFilesQuery({ files: [file] })),
    filesDeleteMutationResolver = jest.fn().mockResolvedValue(packageDestroyFilesMutation()),
    options = {},
  } = {}) => {
    const requestHandlers = [
      [getPackageFiles, resolver],
      [destroyPackageFilesMutation, filesDeleteMutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(PackageFiles, {
      apolloProvider,
      propsData: {
        canDelete,
        deleteAllFiles,
        packageId,
        packageType,
        projectPath,
      },
      stubs: {
        GlTable: false,
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showMock,
          },
        }),
        ...stubs,
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  describe('rows', () => {
    it('do not get rendered when query is loading', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findDeleteSelectedButton().props('disabled')).toBe(true);
    });

    it('renders a single file for an npm package', async () => {
      createComponent();
      await waitForPromises();

      expect(findAllRows()).toHaveLength(1);
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders multiple files for a package that contains more than one file', async () => {
      createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
      await waitForPromises();

      expect(findAllRows()).toHaveLength(2);
    });

    it('does not render gl-alert', async () => {
      createComponent();
      await waitForPromises();

      expect(findPackageFilesAlert().exists()).toBe(false);
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('renders gl-alert if load fails', async () => {
      createComponent({ resolver: jest.fn().mockRejectedValue() });
      await waitForPromises();

      expect(findPackageFilesAlert().exists()).toBe(true);
      expect(findPackageFilesAlert().text()).toBe(
        'Something went wrong while fetching package assets.',
      );
      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('renders pagination', async () => {
      createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
      await waitForPromises();

      const { endCursor, startCursor, hasNextPage, hasPreviousPage } = pagination();

      expect(findPagination().props()).toMatchObject({
        endCursor,
        startCursor,
        hasNextPage,
        hasPreviousPage,
        prevText: PREV,
        nextText: NEXT,
        disabled: false,
      });
    });
  });

  describe('link', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      createComponent();
      return waitForPromises();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('exists', () => {
      expect(findFirstRowDownloadLink().exists()).toBe(true);
    });

    it('has the correct attrs bound', () => {
      expect(findFirstRowDownloadLink().attributes('href')).toBe(file.downloadPath);
    });

    it('tracks "download-file" event on click', () => {
      findFirstRowDownloadLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(
        eventCategory,
        DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
        expect.any(Object),
      );
    });
  });

  describe('file-icon', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('exists', () => {
      expect(findFirstRowFileIcon().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findFirstRowFileIcon().props('fileName')).toBe(file.fileName);
    });
  });

  describe('time-ago tooltip', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('exists', () => {
      expect(findFirstRowCreatedAt().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findFirstRowCreatedAt().props('time')).toBe(file.createdAt);
    });
  });

  describe('action menu', () => {
    describe('when the user can delete', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('exists', () => {
        expect(findFirstActionMenu().exists()).toBe(true);
        expect(findFirstActionMenu().props('icon')).toBe('ellipsis_v');
        expect(findFirstActionMenu().props('textSrOnly')).toBe(true);
        expect(findFirstActionMenu().props('toggleText')).toMatchInterpolatedText('More actions');
      });

      describe('menu items', () => {
        describe('delete file', () => {
          it('exists', () => {
            expect(findActionMenuDelete().exists()).toBe(true);
          });

          it('shows delete file confirmation modal', async () => {
            await findActionMenuDelete().vm.$emit('action');

            expect(showMock).toHaveBeenCalledTimes(1);

            expect(findDeleteFilesModal().text()).toBe(
              'You are about to delete foo-1.0.1.tgz. This is a destructive action that may render your package unusable. Are you sure?',
            );
          });
        });
      });
    });

    describe('when the user can not delete', () => {
      const canDelete = false;

      it('does not exist', async () => {
        createComponent({ canDelete });
        await waitForPromises();

        expect(findFirstActionMenu().exists()).toBe(false);
      });
    });
  });

  describe('multi select', () => {
    describe('when user can delete', () => {
      it('delete selected button exists & is disabled', async () => {
        createComponent();
        await waitForPromises();

        expect(findDeleteSelectedButton().exists()).toBe(true);
        expect(findDeleteSelectedButton().text()).toMatchInterpolatedText('Delete selected');
        expect(findDeleteSelectedButton().props('disabled')).toBe(true);
      });

      it('checkboxes to select file are visible', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
        await waitForPromises();

        expect(findCheckAllCheckbox().exists()).toBe(true);
        expect(findAllRowCheckboxes()).toHaveLength(2);
      });

      it('selecting a checkbox enables delete selected button', async () => {
        createComponent();
        await waitForPromises();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        expect(findDeleteSelectedButton().props('disabled')).toBe(false);
      });

      describe('select all checkbox', () => {
        it('will toggle between selecting all and deselecting all files', async () => {
          const getChecked = () => findAllRowCheckboxes().filter((x) => x.element.checked === true);

          createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
          await waitForPromises();

          expect(getChecked()).toHaveLength(0);

          await findCheckAllCheckbox().setChecked(true);

          expect(getChecked()).toHaveLength(files.length);

          await findCheckAllCheckbox().setChecked(false);

          expect(getChecked()).toHaveLength(0);
        });

        it('will toggle the indeterminate state when some but not all files are selected', async () => {
          const expectIndeterminateState = (state) =>
            expect(findCheckAllCheckbox().props('indeterminate')).toBe(state);

          createComponent({
            resolver: jest.fn().mockResolvedValue(packageFilesQuery()),
            stubs: { GlFormCheckbox: stubComponent(GlFormCheckbox, { props: ['indeterminate'] }) },
          });
          await waitForPromises();

          expectIndeterminateState(false);

          await findSecondRow().trigger('click');

          expectIndeterminateState(true);

          await findSecondRow().trigger('click');

          expectIndeterminateState(false);

          findCheckAllCheckbox().trigger('click');

          expectIndeterminateState(false);

          await findSecondRow().trigger('click');

          expectIndeterminateState(true);
        });
      });

      it('shows delete modal with single file confirmation text when delete selected is clicked', async () => {
        createComponent();
        await waitForPromises();

        const first = findAllRowCheckboxes().at(0);

        await first.setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        expect(showMock).toHaveBeenCalledTimes(1);

        expect(findDeleteFilesModal().text()).toBe(
          'You are about to delete foo-1.0.1.tgz. This is a destructive action that may render your package unusable. Are you sure?',
        );
      });

      it('shows delete modal with multiple files confirmation text when delete selected is clicked', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()) });
        await waitForPromises();

        await findCheckAllCheckbox().setChecked(true);

        await findDeleteSelectedButton().trigger('click');

        expect(showMock).toHaveBeenCalledTimes(1);

        expect(findDeleteFilesModal().text()).toMatchInterpolatedText(
          'You are about to delete 2 assets. This operation is irreversible.',
        );
      });

      describe('When deleteAllFiles is disabled', () => {
        const deleteAllFiles = false;

        describe('emits delete-all-files event', () => {
          it('with right content for last file in package', async () => {
            createComponent({
              deleteAllFiles,
              resolver: jest.fn().mockResolvedValue(
                packageFilesQuery({
                  files: [file],
                  extendPagination: {
                    hasPreviousPage: false,
                    hasNextPage: false,
                  },
                }),
              ),
            });
            await waitForPromises();
            const first = findAllRowCheckboxes().at(0);

            await first.setChecked(true);

            await findDeleteSelectedButton().trigger('click');

            expect(showMock).toHaveBeenCalledTimes(0);

            expect(wrapper.emitted('delete-all-files')).toHaveLength(1);
            expect(wrapper.emitted('delete-all-files')[0]).toEqual([
              DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT,
            ]);
          });

          it('with right content for all files in package', async () => {
            createComponent({
              deleteAllFiles,
              resolver: jest.fn().mockResolvedValue(
                packageFilesQuery({
                  extendPagination: {
                    hasPreviousPage: false,
                    hasNextPage: false,
                  },
                }),
              ),
            });
            await waitForPromises();

            await findCheckAllCheckbox().setChecked(true);

            await findDeleteSelectedButton().trigger('click');

            expect(showMock).toHaveBeenCalledTimes(0);

            expect(wrapper.emitted('delete-all-files')).toHaveLength(1);
            expect(wrapper.emitted('delete-all-files')[0]).toEqual([
              DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
            ]);
          });
        });
      });

      describe('When deleteAllFiles is enabled', () => {
        const deleteAllFiles = true;

        describe('deletes and does not emit delete-all-files event', () => {
          it('with right content for last file in package', async () => {
            createComponent({
              deleteAllFiles,
              resolver: jest.fn().mockResolvedValue(
                packageFilesQuery({
                  files: [file],
                  extendPagination: {
                    hasPreviousPage: false,
                    hasNextPage: false,
                  },
                }),
              ),
            });
            await waitForPromises();
            const first = findAllRowCheckboxes().at(0);

            await first.setChecked(true);

            await findDeleteSelectedButton().trigger('click');

            expect(showMock).toHaveBeenCalledTimes(1);
            expect(findDeleteFilesModal().text()).toMatchInterpolatedText(
              'You are about to delete foo-1.0.1.tgz. This is a destructive action that may render your package unusable. Are you sure?',
            );
            expect(wrapper.emitted('delete-all-files')).toBeUndefined();
          });

          it('with right content for all files in package', async () => {
            createComponent({
              deleteAllFiles,
              resolver: jest.fn().mockResolvedValue(
                packageFilesQuery({
                  extendPagination: {
                    hasPreviousPage: false,
                    hasNextPage: false,
                  },
                }),
              ),
            });
            await waitForPromises();

            await findCheckAllCheckbox().setChecked(true);

            await findDeleteSelectedButton().trigger('click');

            expect(showMock).toHaveBeenCalledTimes(1);
            expect(findDeleteFilesModal().text()).toMatchInterpolatedText(
              'You are about to delete 2 assets. This operation is irreversible.',
            );
            expect(wrapper.emitted('delete-all-files')).toBeUndefined();
          });
        });
      });
    });

    describe('when user cannot delete', () => {
      const canDelete = false;

      it('delete selected button does not exist', async () => {
        createComponent({ canDelete });
        await waitForPromises();

        expect(findDeleteSelectedButton().exists()).toBe(false);
      });

      it('checkboxes to select file are not visible', async () => {
        createComponent({ resolver: jest.fn().mockResolvedValue(packageFilesQuery()), canDelete });
        await waitForPromises();

        expect(findCheckAllCheckbox().exists()).toBe(false);
        expect(findAllRowCheckboxes()).toHaveLength(0);
      });
    });
  });

  describe('when user interacts with pagination', () => {
    const resolver = jest.fn().mockResolvedValue(packageFilesQuery());

    beforeEach(async () => {
      createComponent({ resolver, options: { attachTo: document.body } });
      await waitForPromises();
    });

    describe('when list emits next event', () => {
      beforeEach(() => {
        findPagination().vm.$emit('next');
      });

      it('fetches the next set of files', () => {
        expect(resolver).toHaveBeenLastCalledWith(
          expect.objectContaining({
            after: pagination().endCursor,
            first: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
          }),
        );
      });

      it('scrolls to top of package files component', async () => {
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledWith(wrapper.vm.$el);
      });

      it('first row is the active element', async () => {
        await waitForPromises();

        expect(findFirstRow().element).toBe(document.activeElement);
      });
    });

    describe('when list emits prev event', () => {
      beforeEach(() => {
        findPagination().vm.$emit('prev');
      });

      it('fetches the previous set of files', () => {
        expect(resolver).toHaveBeenLastCalledWith(
          expect.objectContaining({
            before: pagination().startCursor,
            last: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
          }),
        );
      });

      it('scrolls to top of package files component', async () => {
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledWith(wrapper.vm.$el);
      });

      it('first row is the active element', async () => {
        await waitForPromises();

        expect(findFirstRow().element).toBe(document.activeElement);
      });
    });
  });

  describe('deleting a file', () => {
    const doDeleteFile = async () => {
      const first = findAllRowCheckboxes().at(0);

      await first.setChecked(true);

      await findDeleteSelectedButton().trigger('click');

      findDeleteFilesModal().vm.$emit('primary');
    };

    it('confirming on the modal sets the loading state', async () => {
      createComponent();

      await waitForPromises();

      await doDeleteFile();

      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findPagination().props('disabled')).toBe(true);
    });

    it('confirming on the modal deletes the file and shows a success message', async () => {
      const resolver = jest.fn().mockResolvedValue(packageFilesQuery({ files: [file] }));
      const filesDeleteMutationResolver = jest
        .fn()
        .mockResolvedValue(packageDestroyFilesMutation());
      createComponent({ resolver, filesDeleteMutationResolver });

      await waitForPromises();

      await doDeleteFile();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
        }),
      );

      expect(filesDeleteMutationResolver).toHaveBeenCalledWith({
        ids: [file.id],
        projectPath: 'gitlab-test',
      });

      // we are re-fetching the package files, so we expect the resolver to have been called twice
      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenCalledWith({
        id: '1',
        first: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
      });
    });

    describe('errors', () => {
      it('shows an error when the mutation request fails', async () => {
        createComponent({ filesDeleteMutationResolver: jest.fn().mockRejectedValue() });
        await waitForPromises();

        await doDeleteFile();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
          }),
        );
      });

      it('shows an error when the mutation request returns an error payload', async () => {
        createComponent({
          filesDeleteMutationResolver: jest
            .fn()
            .mockResolvedValue(packageDestroyFilesMutationError()),
        });
        await waitForPromises();

        await doDeleteFile();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
          }),
        );
      });
    });
  });

  describe('deleting multiple files', () => {
    const doDeleteFiles = async () => {
      await findCheckAllCheckbox().setChecked(true);

      await findDeleteSelectedButton().trigger('click');

      findDeleteFilesModal().vm.$emit('primary');
    };

    it('confirming on the modal sets the loading state', async () => {
      createComponent();

      await waitForPromises();

      await doDeleteFiles();

      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findPagination().props('disabled')).toBe(true);
    });

    it('confirming on the modal deletes the file and shows a success message', async () => {
      const resolver = jest.fn().mockResolvedValue(packageFilesQuery());
      const filesDeleteMutationResolver = jest
        .fn()
        .mockResolvedValue(packageDestroyFilesMutation());
      createComponent({ resolver, filesDeleteMutationResolver });

      await waitForPromises();

      await doDeleteFiles();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
        }),
      );

      expect(filesDeleteMutationResolver).toHaveBeenCalledWith({
        ids: files.map(({ id }) => id),
        projectPath: 'gitlab-test',
      });

      // we are re-fetching the package files, so we expect the resolver to have been called twice
      expect(resolver).toHaveBeenCalledTimes(2);
      expect(resolver).toHaveBeenCalledWith({
        id: '1',
        first: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
      });
    });

    describe('errors', () => {
      it('shows an error when the mutation request fails', async () => {
        const resolver = jest.fn().mockResolvedValue(packageFilesQuery());
        createComponent({ filesDeleteMutationResolver: jest.fn().mockRejectedValue(), resolver });
        await waitForPromises();

        await doDeleteFiles();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILES_ERROR_MESSAGE,
          }),
        );
      });

      it('shows an error when the mutation request returns an error payload', async () => {
        const resolver = jest.fn().mockResolvedValue(packageFilesQuery());
        createComponent({
          filesDeleteMutationResolver: jest
            .fn()
            .mockResolvedValue(packageDestroyFilesMutationError()),
          resolver,
        });
        await waitForPromises();

        await doDeleteFiles();

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILES_ERROR_MESSAGE,
          }),
        );
      });
    });
  });
  describe('additional details', () => {
    describe('details toggle button', () => {
      it('exists', async () => {
        createComponent();
        await waitForPromises();

        expect(findFirstToggleDetailsButton().exists()).toBe(true);
      });

      it('is hidden when no details is present', async () => {
        const { ...noShaFile } = file;
        noShaFile.fileSha256 = null;
        noShaFile.fileMd5 = null;
        noShaFile.fileSha1 = null;
        createComponent({
          resolver: jest.fn().mockResolvedValue(packageFilesQuery({ files: [noShaFile] })),
        });
        await waitForPromises();

        expect(findFirstToggleDetailsButton().exists()).toBe(false);
      });

      it('toggles the details row', async () => {
        createComponent();
        await waitForPromises();

        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-down');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(true);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-up');

        findFirstToggleDetailsButton().vm.$emit('click');
        await nextTick();

        expect(findFirstRowShaComponent('sha-256').exists()).toBe(false);
        expect(findFirstToggleDetailsButton().props('icon')).toBe('chevron-down');
      });
    });

    describe('file shas', () => {
      const showShaFiles = () => {
        findFirstToggleDetailsButton().vm.$emit('click');
        return nextTick();
      };

      it.each`
        selector     | title        | sha
        ${'sha-256'} | ${'SHA-256'} | ${'fileSha256'}
        ${'md5'}     | ${'MD5'}     | ${'fileMd5'}
        ${'sha-1'}   | ${'SHA-1'}   | ${'be93151dc23ac34a82752444556fe79b32c7a1ad'}
      `('has a $title row', async ({ selector, title, sha }) => {
        createComponent();
        await waitForPromises();

        await showShaFiles();

        expect(findFirstRowShaComponent(selector).props()).toMatchObject({
          title,
          sha,
        });
      });

      it('does not display a row when the data is missing', async () => {
        const { ...missingMd5 } = file;
        missingMd5.fileMd5 = null;

        createComponent({
          resolver: jest.fn().mockResolvedValue(packageFilesQuery({ files: [missingMd5] })),
        });
        await waitForPromises();

        await showShaFiles();

        expect(findFirstRowShaComponent('md5').exists()).toBe(false);
      });
    });
  });

  describe('upload slot', () => {
    const resolver = jest.fn().mockResolvedValue(packageFilesQuery({ files: [file] }));
    const findUploadSlot = () => wrapper.findByTestId('upload-slot');

    beforeEach(async () => {
      createComponent({
        resolver,
        options: {
          scopedSlots: {
            upload(props) {
              return this.$createElement('div', {
                attrs: {
                  'data-testid': 'upload-slot',
                  ...props,
                },
                on: {
                  click: () => {
                    return props.refetch();
                  },
                },
              });
            },
          },
        },
      });
      await waitForPromises();
    });

    it('should render slot content', () => {
      expect(findUploadSlot().attributes()).toMatchObject({ refetch: expect.anything() });
    });

    it('should refetch when clicked', async () => {
      await findUploadSlot().trigger('click');
      expect(resolver).toHaveBeenCalledTimes(2);
    });
  });
});
