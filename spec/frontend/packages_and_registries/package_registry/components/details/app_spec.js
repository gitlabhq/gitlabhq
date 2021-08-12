import { GlEmptyState, GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import {
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  DELETE_PACKAGE_ERROR_MESSAGE,
  PACKAGE_TYPE_COMPOSER,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  PACKAGE_TYPE_NUGET,
} from '~/packages_and_registries/package_registry/constants';

import destroyPackageMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package.mutation.graphql';
import destroyPackageFileMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_file.mutation.graphql';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import {
  packageDetailsQuery,
  packageData,
  packageVersions,
  dependencyLinks,
  emptyPackageDetailsQuery,
  packageDestroyMutation,
  packageDestroyMutationError,
  packageFiles,
  packageDestroyFileMutation,
  packageDestroyFileMutationError,
} from '../../mock_data';

jest.mock('~/flash');
useMockLocationHelper();

const localVue = createLocalVue();

describe('PackagesApp', () => {
  let wrapper;
  let apolloProvider;

  const provide = {
    packageId: '111',
    titleComponent: 'PackageTitle',
    projectName: 'projectName',
    canDelete: 'canDelete',
    svgPath: 'svgPath',
    npmPath: 'npmPath',
    npmHelpPath: 'npmHelpPath',
    projectListUrl: 'projectListUrl',
    groupListUrl: 'groupListUrl',
  };

  function createComponent({
    resolver = jest.fn().mockResolvedValue(packageDetailsQuery()),
    mutationResolver = jest.fn().mockResolvedValue(packageDestroyMutation()),
    fileDeleteMutationResolver = jest.fn().mockResolvedValue(packageDestroyFileMutation()),
  } = {}) {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getPackageDetails, resolver],
      [destroyPackageMutation, mutationResolver],
      [destroyPackageFileMutation, fileDeleteMutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackagesApp, {
      localVue,
      apolloProvider,
      provide,
      stubs: {
        PackageTitle,
        GlModal: {
          template: '<div></div>',
          methods: {
            show: jest.fn(),
          },
        },
        GlTabs,
        GlTab,
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
  const findVersionRows = () => wrapper.findAllComponents(VersionRow);
  const noVersionsMessage = () => wrapper.findByTestId('no-versions-message');
  const findDependenciesCountBadge = () => wrapper.findComponent(GlBadge);
  const findNoDependenciesMessage = () => wrapper.findByTestId('no-dependencies-message');
  const findDependencyRows = () => wrapper.findAllComponents(DependencyRow);

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
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  it('emits an error message if the load fails', async () => {
    createComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(createFlash).toHaveBeenCalledWith(
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
      packageEntity: expect.objectContaining(packageData()),
      projectName: provide.projectName,
    });
  });

  it('renders additional metadata and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findAdditionalMetadata().exists()).toBe(true);
    expect(findAdditionalMetadata().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  it('renders installation commands and has the right props', async () => {
    createComponent();

    await waitForPromises();

    expect(findInstallationCommands().exists()).toBe(true);
    expect(findInstallationCommands().props()).toMatchObject({
      packageEntity: expect.objectContaining(packageData()),
    });
  });

  describe('delete package', () => {
    const originalReferrer = document.referrer;
    const setReferrer = (value = provide.projectName) => {
      Object.defineProperty(document, 'referrer', {
        value,
        configurable: true,
      });
    };

    const performDeletePackage = async () => {
      await findDeleteButton().trigger('click');

      findDeleteModal().vm.$emit('primary');

      await waitForPromises();
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

      expect(findDeleteModal().exists()).toBe(true);
    });

    describe('successful request', () => {
      it('when referrer contains project name calls window.replace with project url', async () => {
        setReferrer();

        createComponent();

        await waitForPromises();

        await performDeletePackage();

        expect(window.location.replace).toHaveBeenCalledWith(
          'projectListUrl?showSuccessDeleteAlert=true',
        );
      });

      it('when referrer does not contain project name calls window.replace with group url', async () => {
        setReferrer('baz');

        createComponent();

        await waitForPromises();

        await performDeletePackage();

        expect(window.location.replace).toHaveBeenCalledWith(
          'groupListUrl?showSuccessDeleteAlert=true',
        );
      });
    });

    describe('request failure', () => {
      it('on global failure it displays an alert', async () => {
        createComponent({ mutationResolver: jest.fn().mockRejectedValue() });

        await waitForPromises();

        await performDeletePackage();

        expect(createFlash).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_ERROR_MESSAGE,
          }),
        );
      });

      it('on payload with error it displays an alert', async () => {
        createComponent({
          mutationResolver: jest.fn().mockResolvedValue(packageDestroyMutationError()),
        });

        await waitForPromises();

        await performDeletePackage();

        expect(createFlash).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_ERROR_MESSAGE,
          }),
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

      const doDeleteFile = () => {
        findPackageFiles().vm.$emit('delete-file', fileToDelete);

        findDeleteFileModal().vm.$emit('primary');

        return waitForPromises();
      };

      it('opens a confirmation modal', async () => {
        createComponent();

        await waitForPromises();

        findPackageFiles().vm.$emit('delete-file', fileToDelete);

        await nextTick();

        expect(findDeleteFileModal().exists()).toBe(true);
      });

      it('confirming on the modal deletes the file and shows a success message', async () => {
        const resolver = jest.fn().mockResolvedValue(packageDetailsQuery());
        createComponent({ resolver });

        await waitForPromises();

        await doDeleteFile();

        expect(createFlash).toHaveBeenCalledWith(
          expect.objectContaining({
            message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
          }),
        );
        // we are re-fetching the package details, so we expect the resolver to have been called twice
        expect(resolver).toHaveBeenCalledTimes(2);
      });

      describe('errors', () => {
        it('shows an error when the mutation request fails', async () => {
          createComponent({ fileDeleteMutationResolver: jest.fn().mockRejectedValue() });
          await waitForPromises();

          await doDeleteFile();

          expect(createFlash).toHaveBeenCalledWith(
            expect.objectContaining({
              message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
            }),
          );
        });

        it('shows an error when the mutation request returns an error payload', async () => {
          createComponent({
            fileDeleteMutationResolver: jest
              .fn()
              .mockResolvedValue(packageDestroyFileMutationError()),
          });
          await waitForPromises();

          await doDeleteFile();

          expect(createFlash).toHaveBeenCalledWith(
            expect.objectContaining({
              message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
            }),
          );
        });
      });
    });
  });

  describe('versions', () => {
    it('displays the correct version count when the package has versions', async () => {
      createComponent();

      await waitForPromises();

      expect(findVersionRows()).toHaveLength(packageVersions().length);
    });

    it('binds the correct props', async () => {
      const [versionPackage] = packageVersions();
      // eslint-disable-next-line no-underscore-dangle
      delete versionPackage.__typename;
      delete versionPackage.tags;

      createComponent();

      await waitForPromises();

      expect(findVersionRows().at(0).props()).toMatchObject({
        packageEntity: expect.objectContaining(versionPackage),
      });
    });

    it('displays the no versions message when there are none', async () => {
      createComponent({
        resolver: jest.fn().mockResolvedValue(packageDetailsQuery({ versions: { nodes: [] } })),
      });

      await waitForPromises();

      expect(noVersionsMessage().exists()).toBe(true);
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
