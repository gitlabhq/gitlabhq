import { GlEmptyState, GlTabs, GlTab, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';

import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import PackagesApp from '~/packages_and_registries/package_registry/pages/details.vue';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import {
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  PACKAGE_TYPE_COMPOSER,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILES_ERROR_MESSAGE,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_NPM,
} from '~/packages_and_registries/package_registry/constants';

import destroyPackageFilesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_files.mutation.graphql';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import {
  packageDetailsQuery,
  packageData,
  packageVersions,
  dependencyLinks,
  emptyPackageDetailsQuery,
  packageFiles,
  packageDestroyFilesMutation,
  packageDestroyFilesMutationError,
  pagination,
} from '../mock_data';

jest.mock('~/flash');
useMockLocationHelper();

describe('PackagesApp', () => {
  let wrapper;
  let apolloProvider;

  const breadCrumbState = {
    updateName: jest.fn(),
  };

  const provide = {
    packageId: '111',
    emptyListIllustration: 'svgPath',
    projectListUrl: 'projectListUrl',
    groupListUrl: 'groupListUrl',
    isGroupPage: false,
    breadCrumbState,
  };

  const { __typename, ...packageWithoutTypename } = packageData();

  function createComponent({
    resolver = jest.fn().mockResolvedValue(packageDetailsQuery()),
    filesDeleteMutationResolver = jest.fn().mockResolvedValue(packageDestroyFilesMutation()),
    routeId = '1',
  } = {}) {
    Vue.use(VueApollo);

    const requestHandlers = [
      [getPackageDetails, resolver],
      [destroyPackageFilesMutation, filesDeleteMutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackagesApp, {
      apolloProvider,
      provide,
      stubs: {
        PackageTitle,
        DeletePackages,
        GlModal: {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <p><slot></slot></p>
            </div>
          `,
          methods: {
            show: jest.fn(),
          },
        },
        GlSprintf,
        GlTabs,
        GlTab,
        PackageVersionsList,
      },
      mocks: {
        $route: {
          params: {
            id: routeId,
          },
        },
      },
    });
  }

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findAdditionalMetadata = () => wrapper.findComponent(AdditionalMetadata);
  const findInstallationCommands = () => wrapper.findComponent(InstallationCommands);
  const findDeleteModal = () => wrapper.findByTestId('delete-modal');
  const findDeleteButton = () => wrapper.findByTestId('delete-package');
  const findPackageFiles = () => wrapper.findComponent(PackageFiles);
  const findDeleteFileModal = () => wrapper.findByTestId('delete-file-modal');
  const findDeleteFilesModal = () => wrapper.findByTestId('delete-files-modal');
  const findVersionsList = () => wrapper.findComponent(PackageVersionsList);
  const findVersionsCountBadge = () => wrapper.findByTestId('other-versions-badge');
  const findNoVersionsMessage = () => wrapper.findByTestId('no-versions-message');
  const findDependenciesCountBadge = () => wrapper.findByTestId('dependencies-badge');
  const findNoDependenciesMessage = () => wrapper.findByTestId('no-dependencies-message');
  const findDependencyRows = () => wrapper.findAllComponents(DependencyRow);
  const findDeletePackages = () => wrapper.findComponent(DeletePackages);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state component', async () => {
    createComponent({ resolver: jest.fn().mockResolvedValue(emptyPackageDetailsQuery) });

    await waitForPromises();

    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders the app and displays the package title', async () => {
    createComponent();

    await waitForPromises();

    expect(findPackageTitle().exists()).toBe(true);
    expect(findPackageTitle().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageWithoutTypename),
    });
  });

  it('emits an error message if the load fails', async () => {
    createComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        message: FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
      }),
    );
  });

  it('renders history and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findPackageHistory().exists()).toBe(true);
    expect(findPackageHistory().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageWithoutTypename),
      projectName: packageDetailsQuery().data.package.project.name,
    });
  });

  describe('additional metadata', () => {
    it.each`
      packageType              | visible
      ${PACKAGE_TYPE_MAVEN}    | ${true}
      ${PACKAGE_TYPE_CONAN}    | ${true}
      ${PACKAGE_TYPE_NUGET}    | ${true}
      ${PACKAGE_TYPE_COMPOSER} | ${true}
      ${PACKAGE_TYPE_PYPI}     | ${true}
      ${PACKAGE_TYPE_NPM}      | ${false}
    `(
      `is $visible that the component is visible when the package is $packageType`,
      async ({ packageType, visible }) => {
        createComponent({
          resolver: jest.fn().mockResolvedValue(
            packageDetailsQuery({
              packageType,
            }),
          ),
        });

        await waitForPromises();

        expect(findAdditionalMetadata().exists()).toBe(visible);

        if (visible) {
          expect(findAdditionalMetadata().props()).toMatchObject({
            packageId: packageWithoutTypename.id,
            packageType,
          });
        }
      },
    );
  });

  it('renders installation commands and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findInstallationCommands().exists()).toBe(true);
    expect(findInstallationCommands().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageWithoutTypename),
    });
  });

  it('calls the appropriate function to set the breadcrumbState', async () => {
    const { name, version } = packageData();
    createComponent();

    await waitForPromises();

    expect(breadCrumbState.updateName).toHaveBeenCalledWith(`${name} v ${version}`);
  });

  describe('delete package', () => {
    const originalReferrer = document.referrer;
    const setReferrer = (value = packageDetailsQuery().data.package.project.name) => {
      Object.defineProperty(document, 'referrer', {
        value,
        configurable: true,
      });
    };

    afterEach(() => {
      Object.defineProperty(document, 'referrer', {
        value: originalReferrer,
        configurable: true,
      });
    });

    it('shows the delete confirmation modal when delete is clicked', async () => {
      createComponent();

      await waitForPromises();

      await findDeleteButton().trigger('click');

      expect(findDeleteModal().find('p').text()).toBe(
        'You are about to delete version 1.0.0 of @gitlab-org/package-15. Are you sure?',
      );
    });

    describe('successful request', () => {
      it('when referrer contains project name calls window.replace with project url', async () => {
        setReferrer();

        createComponent();

        await waitForPromises();

        findDeletePackages().vm.$emit('end');

        expect(window.location.replace).toHaveBeenCalledWith(
          'projectListUrl?showSuccessDeleteAlert=true',
        );
      });

      it('when referrer does not contain project name calls window.replace with group url', async () => {
        setReferrer('baz');

        createComponent();

        await waitForPromises();

        findDeletePackages().vm.$emit('end');

        expect(window.location.replace).toHaveBeenCalledWith(
          'groupListUrl?showSuccessDeleteAlert=true',
        );
      });
    });
  });

  describe('package files', () => {
    it('renders the package files component and has the right props', async () => {
      const expectedFile = { ...packageFiles()[0] };
      // eslint-disable-next-line no-underscore-dangle
      delete expectedFile.__typename;
      createComponent();

      await waitForPromises();

      expect(findPackageFiles().exists()).toBe(true);

      expect(findPackageFiles().props('packageFiles')[0]).toMatchObject(expectedFile);
      expect(findPackageFiles().props('canDelete')).toBe(packageData().canDestroy);
      expect(findPackageFiles().props('isLoading')).toEqual(false);
    });

    it('does not render the package files table when the package is composer', async () => {
      createComponent({
        resolver: jest
          .fn()
          .mockResolvedValue(packageDetailsQuery({ packageType: PACKAGE_TYPE_COMPOSER })),
      });

      await waitForPromises();

      expect(findPackageFiles().exists()).toBe(false);
    });

    describe('deleting a file', () => {
      const [fileToDelete] = packageFiles();

      const doDeleteFile = async () => {
        findPackageFiles().vm.$emit('delete-files', [fileToDelete]);

        findDeleteFileModal().vm.$emit('primary');

        return waitForPromises();
      };

      it('opens delete file confirmation modal', async () => {
        createComponent();

        await waitForPromises();

        const showDeleteFileSpy = jest.spyOn(wrapper.vm.$refs.deleteFileModal, 'show');
        const showDeletePackageSpy = jest.spyOn(wrapper.vm.$refs.deleteModal, 'show');

        findPackageFiles().vm.$emit('delete-files', [fileToDelete]);

        expect(showDeletePackageSpy).not.toHaveBeenCalled();
        expect(showDeleteFileSpy).toHaveBeenCalled();
      });

      it('when its the only file opens delete package confirmation modal', async () => {
        const [packageFile] = packageFiles();
        const resolver = jest.fn().mockResolvedValue(
          packageDetailsQuery({
            packageFiles: {
              pageInfo: {
                hasNextPage: false,
              },
              nodes: [packageFile],
              __typename: 'PackageFileConnection',
            },
          }),
        );

        createComponent({
          resolver,
        });

        await waitForPromises();

        const showDeleteFileSpy = jest.spyOn(wrapper.vm.$refs.deleteFileModal, 'show');
        const showDeletePackageSpy = jest.spyOn(wrapper.vm.$refs.deleteModal, 'show');

        findPackageFiles().vm.$emit('delete-files', [fileToDelete]);

        expect(showDeletePackageSpy).toHaveBeenCalled();
        expect(showDeleteFileSpy).not.toHaveBeenCalled();

        await waitForPromises();

        expect(findDeleteModal().find('p').text()).toBe(
          'Deleting the last package asset will remove version 1.0.0 of @gitlab-org/package-15. Are you sure?',
        );
      });

      it('confirming on the modal sets the loading state', async () => {
        createComponent();

        await waitForPromises();

        findPackageFiles().vm.$emit('delete-files', [fileToDelete]);

        findDeleteFileModal().vm.$emit('primary');

        await nextTick();

        expect(findPackageFiles().props('isLoading')).toEqual(true);
      });

      it('confirming on the modal deletes the file and shows a success message', async () => {
        const resolver = jest.fn().mockResolvedValue(packageDetailsQuery());
        createComponent({ resolver });

        await waitForPromises();

        await doDeleteFile();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
          }),
        );
        // we are re-fetching the package details, so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
      });

      describe('errors', () => {
        it('shows an error when the mutation request fails', async () => {
          createComponent({ filesDeleteMutationResolver: jest.fn().mockRejectedValue() });
          await waitForPromises();

          await doDeleteFile();

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
        findPackageFiles().vm.$emit('delete-files', packageFiles());

        findDeleteFilesModal().vm.$emit('primary');

        return waitForPromises();
      };

      it('opens delete files confirmation modal', async () => {
        createComponent();

        await waitForPromises();

        const showDeleteFilesSpy = jest.spyOn(wrapper.vm.$refs.deleteFilesModal, 'show');

        findPackageFiles().vm.$emit('delete-files', packageFiles());

        expect(showDeleteFilesSpy).toHaveBeenCalled();
      });

      it('confirming on the modal sets the loading state', async () => {
        createComponent();

        await waitForPromises();

        findPackageFiles().vm.$emit('delete-files', packageFiles());

        findDeleteFilesModal().vm.$emit('primary');

        await nextTick();

        expect(findPackageFiles().props('isLoading')).toEqual(true);
      });

      it('confirming on the modal deletes the file and shows a success message', async () => {
        const resolver = jest.fn().mockResolvedValue(packageDetailsQuery());
        createComponent({ resolver });

        await waitForPromises();

        await doDeleteFiles();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
          }),
        );
        // we are re-fetching the package details, so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
      });

      describe('errors', () => {
        it('shows an error when the mutation request fails', async () => {
          createComponent({ filesDeleteMutationResolver: jest.fn().mockRejectedValue() });
          await waitForPromises();

          await doDeleteFiles();

          expect(createAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: DELETE_PACKAGE_FILES_ERROR_MESSAGE,
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

          await doDeleteFiles();

          expect(createAlert).toHaveBeenCalledWith(
            expect.objectContaining({
              message: DELETE_PACKAGE_FILES_ERROR_MESSAGE,
            }),
          );
        });
      });
    });

    describe('deleting all files', () => {
      it('opens the delete package confirmation modal', async () => {
        const resolver = jest.fn().mockResolvedValue(
          packageDetailsQuery({
            packageFiles: {
              pageInfo: {
                hasNextPage: false,
              },
              nodes: packageFiles(),
            },
          }),
        );
        createComponent({
          resolver,
        });

        await waitForPromises();

        const showDeletePackageSpy = jest.spyOn(wrapper.vm.$refs.deleteModal, 'show');

        findPackageFiles().vm.$emit('delete-files', packageFiles());

        expect(showDeletePackageSpy).toHaveBeenCalled();

        await waitForPromises();

        expect(findDeleteModal().find('p').text()).toBe(
          'Deleting all package assets will remove version 1.0.0 of @gitlab-org/package-15. Are you sure?',
        );
      });
    });
  });

  describe('versions', () => {
    it('displays versions list when the package has versions', async () => {
      createComponent();

      await waitForPromises();

      expect(findVersionsList()).toBeDefined();
      expect(findVersionsCountBadge().exists()).toBe(true);
      expect(findVersionsCountBadge().text()).toBe(packageVersions().length.toString());
    });

    it('displays tab with 0 count when package has no other versions', async () => {
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            versions: {
              count: 0,
              nodes: [],
              pageInfo: pagination({ hasNextPage: false, hasPreviousPage: false }),
            },
          }),
        ),
      });

      await waitForPromises();

      expect(findVersionsCountBadge().exists()).toBe(true);
      expect(findVersionsCountBadge().text()).toBe('0');
      expect(findNoVersionsMessage().text()).toMatchInterpolatedText(
        'There are no other versions of this package.',
      );
    });

    it('binds the correct props', async () => {
      const versionNodes = packageVersions();
      createComponent({ packageEntity: { versions: { nodes: versionNodes } } });
      await waitForPromises();

      expect(findVersionsList().props()).toMatchObject({
        versions: expect.arrayContaining(versionNodes),
      });
    });
  });

  describe('dependency links', () => {
    it('does not show the dependency links for a non nuget package', async () => {
      createComponent();

      expect(findDependenciesCountBadge().exists()).toBe(false);
    });

    it('shows the dependencies tab with 0 count when a nuget package with no dependencies', async () => {
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            packageType: PACKAGE_TYPE_NUGET,
            dependencyLinks: { nodes: [] },
          }),
        ),
      });

      await waitForPromises();

      expect(findDependenciesCountBadge().exists()).toBe(true);
      expect(findDependenciesCountBadge().text()).toBe('0');
      expect(findNoDependenciesMessage().exists()).toBe(true);
    });

    it('renders the correct number of dependency rows for a nuget package', async () => {
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            packageType: PACKAGE_TYPE_NUGET,
          }),
        ),
      });
      await waitForPromises();

      expect(findDependenciesCountBadge().exists()).toBe(true);
      expect(findDependenciesCountBadge().text()).toBe(dependencyLinks().length.toString());
      expect(findDependencyRows()).toHaveLength(dependencyLinks().length);
    });
  });
});
