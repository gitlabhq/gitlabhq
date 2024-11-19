import { GlAlert, GlEmptyState, GlModal, GlTabs, GlTab, GlSprintf, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { stubComponent } from 'helpers/stub_component';
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
  REQUEST_FORWARDING_HELP_PAGE_PATH,
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  PACKAGE_TYPE_COMPOSER,
  DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
  PACKAGE_DEPRECATED_STATUS,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_NPM,
} from '~/packages_and_registries/package_registry/constants';

import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import getGroupPackageSettings from '~/packages_and_registries/package_registry/graphql/queries/get_group_package_settings.query.graphql';
import getPackageVersionsQuery from '~/packages_and_registries/package_registry/graphql//queries/get_package_versions.query.graphql';
import {
  packageDetailsQuery,
  groupPackageSettingsQuery,
  packageData,
  packageVersions,
  dependencyLinks,
  emptyPackageDetailsQuery,
  defaultPackageGroupSettings,
} from '../mock_data';

jest.mock('~/alert');
useMockLocationHelper();

Vue.use(VueApollo);

describe('PackagesApp', () => {
  let wrapper;
  let apolloProvider;

  const breadCrumbState = {
    updateName: jest.fn(),
  };

  const provide = {
    packageId: '1',
    emptyListIllustration: 'svgPath',
    projectListUrl: 'projectListUrl',
    groupListUrl: 'groupListUrl',
    isGroupPage: false,
    breadCrumbState,
  };

  const { __typename, ...packageWithoutTypename } = packageData();
  const showMock = jest.fn();

  function createComponent({
    resolver = jest.fn().mockResolvedValue(packageDetailsQuery()),
    groupSettingsResolver = jest.fn().mockResolvedValue(groupPackageSettingsQuery()),
    routeId = '1',
    stubs = {},
  } = {}) {
    const requestHandlers = [
      [getPackageDetails, resolver],
      [getGroupPackageSettings, groupSettingsResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackagesApp, {
      apolloProvider,
      provide,
      stubs: {
        PackageTitle,
        DeletePackages,
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showMock,
          },
        }),
        GlSprintf,
        GlTabs,
        GlTab,
        ...stubs,
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

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findAdditionalMetadata = () => wrapper.findComponent(AdditionalMetadata);
  const findInstallationCommands = () => wrapper.findComponent(InstallationCommands);
  const findDeleteModal = () => wrapper.findByTestId('delete-modal');
  const findDeleteButton = () => wrapper.findByTestId('delete-package');
  const findPackageFiles = () => wrapper.findComponent(PackageFiles);
  const findVersionsList = () => wrapper.findComponent(PackageVersionsList);
  const findVersionsCountBadge = () => wrapper.findByTestId('other-versions-badge');
  const findNoVersionsMessage = () => wrapper.findByTestId('no-versions-message');
  const findDependenciesCountBadge = () => wrapper.findByTestId('dependencies-badge');
  const findNoDependenciesMessage = () => wrapper.findByTestId('no-dependencies-message');
  const findDependencyRows = () => wrapper.findAllComponents(DependencyRow);
  const findDeletePackageModal = () => wrapper.findAllComponents(DeletePackages).at(1);
  const findDeletePackages = () => wrapper.findComponent(DeletePackages);
  const findLink = () => wrapper.findComponent(GlLink);

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

  describe('group package settings graphql query', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
    });

    it('is not called when userPermissions.destroyPackage is false', async () => {
      const groupSettingsResolver = jest.fn().mockResolvedValue(groupPackageSettingsQuery());
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            extendPackage: {
              userPermissions: {
                destroyPackage: false,
              },
            },
          }),
        ),
        groupSettingsResolver,
      });

      await waitForPromises();

      expect(groupSettingsResolver).not.toHaveBeenCalled();
      expect(findPackageFiles().props('canDelete')).toBe(false);
      expect(findVersionsList().props()).toMatchObject({
        canDestroy: false,
        isRequestForwardingEnabled: false,
      });
    });

    it.each`
      packageType              | requested
      ${PACKAGE_TYPE_MAVEN}    | ${true}
      ${PACKAGE_TYPE_CONAN}    | ${false}
      ${PACKAGE_TYPE_NUGET}    | ${false}
      ${PACKAGE_TYPE_COMPOSER} | ${false}
      ${PACKAGE_TYPE_PYPI}     | ${true}
      ${PACKAGE_TYPE_NPM}      | ${true}
    `(`is $requested when package type is $packageType`, async ({ packageType, requested }) => {
      const groupSettingsResolver = jest.fn().mockResolvedValue(groupPackageSettingsQuery());
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            extendPackage: {
              packageType,
            },
          }),
        ),
        groupSettingsResolver,
        stubs: {
          PackageFiles: stubComponent(PackageFiles),
          PackageVersionsList: stubComponent(PackageVersionsList),
        },
      });

      await waitForPromises();

      if (requested) {
        expect(groupSettingsResolver).toHaveBeenCalledWith({
          fullPath: 'gitlab-test',
          isGroupPage: false,
        });
        expect(Sentry.captureException).not.toHaveBeenCalled();
      } else {
        expect(groupSettingsResolver).not.toHaveBeenCalled();
      }
      expect(findVersionsList().props('isRequestForwardingEnabled')).toBe(requested);
    });

    it('when request fails captures error in Sentry', async () => {
      createComponent({
        groupSettingsResolver: jest.fn().mockRejectedValue(),
      });

      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findVersionsList().props('isRequestForwardingEnabled')).toBe(false);
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
              extendPackage: {
                packageType,
              },
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

  describe('deprecation alert', () => {
    it('is not rendered by default', async () => {
      createComponent({
        stubs: {
          PackageFiles: stubComponent(PackageFiles),
          PackageVersionsList: stubComponent(PackageVersionsList),
        },
      });

      await waitForPromises();

      expect(findAlert().exists()).toBe(false);
    });

    describe('when package has deprecated status', () => {
      beforeEach(async () => {
        createComponent({
          resolver: jest
            .fn()
            .mockResolvedValue(
              packageDetailsQuery({ extendPackage: { status: PACKAGE_DEPRECATED_STATUS } }),
            ),
        });

        await waitForPromises();
      });

      it('renders alert', () => {
        expect(findAlert().props('variant')).toBe('warning');
        expect(findAlert().props('dismissible')).toBe(false);
      });

      it('renders alert with the deprecated text', () => {
        expect(findAlert().text()).toBe('This package version has been deprecated.');
      });
    });
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

    expect(breadCrumbState.updateName).toHaveBeenCalledWith(`${name} v${version}`);
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

    describe('when delete button is clicked', () => {
      describe('with request forwarding enabled', () => {
        beforeEach(async () => {
          createComponent();

          await waitForPromises();

          await findDeleteButton().trigger('click');
        });

        it('shows the delete confirmation modal with request forwarding content', () => {
          expect(findDeleteModal().text()).toBe(
            'Deleting this package while request forwarding is enabled for the project can pose a security risk. Do you want to delete @gitlab-org/package-15 version 1.0.0 anyway? What are the risks?',
          );
        });

        it('contains link to help page', () => {
          expect(findLink().exists()).toBe(true);
          expect(findLink().attributes('href')).toBe(REQUEST_FORWARDING_HELP_PAGE_PATH);
        });
      });

      it('shows the delete confirmation modal without request forwarding content', async () => {
        const groupSettingsResolver = jest.fn().mockResolvedValue(
          groupPackageSettingsQuery({
            packageSettings: {
              ...defaultPackageGroupSettings,
              npmPackageRequestsForwarding: false,
            },
          }),
        );
        createComponent({ groupSettingsResolver });

        await waitForPromises();

        await findDeleteButton().trigger('click');

        expect(findDeleteModal().text()).toBe(
          'You are about to delete version 1.0.0 of @gitlab-org/package-15. Are you sure?',
        );
      });
    });

    describe('successful request', () => {
      it('when referrer contains project name calls window.replace with project url', async () => {
        setReferrer();

        createComponent();

        await waitForPromises();

        findDeletePackageModal().vm.$emit('end');

        expect(window.location.replace).toHaveBeenCalledWith(
          'projectListUrl?showSuccessDeleteAlert=true',
        );
      });

      it('when referrer does not contain project name calls window.replace with group url', async () => {
        setReferrer('baz');

        createComponent();

        await waitForPromises();

        findDeletePackageModal().vm.$emit('end');

        expect(window.location.replace).toHaveBeenCalledWith(
          'groupListUrl?showSuccessDeleteAlert=true',
        );
      });
    });
  });

  describe('package files', () => {
    it('renders the package files component and has the right props', async () => {
      createComponent();

      await waitForPromises();

      expect(findPackageFiles().exists()).toBe(true);

      expect(findPackageFiles().props()).toMatchObject({
        canDelete: true,
        packageId: packageData().id,
        packageType: packageData().packageType,
        projectPath: 'gitlab-test',
      });
    });

    it('does not render the package files table when the package is composer', async () => {
      createComponent({
        resolver: jest
          .fn()
          .mockResolvedValue(
            packageDetailsQuery({ extendPackage: { packageType: PACKAGE_TYPE_COMPOSER } }),
          ),
      });

      await waitForPromises();

      expect(findPackageFiles().exists()).toBe(false);
    });

    describe('emits delete-all-files event', () => {
      it('opens the delete package confirmation modal and shows confirmation text', async () => {
        const groupSettingsResolver = jest.fn().mockResolvedValue(
          groupPackageSettingsQuery({
            packageSettings: {
              ...defaultPackageGroupSettings,
              npmPackageRequestsForwarding: false,
            },
          }),
        );
        createComponent({ groupSettingsResolver });

        await waitForPromises();

        findPackageFiles().vm.$emit('delete-all-files', DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT);

        expect(showMock).toHaveBeenCalledTimes(1);

        await nextTick();

        expect(findDeleteModal().text()).toBe(
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
            extendPackage: {
              versions: {
                count: 0,
              },
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
      createComponent();

      await waitForPromises();

      expect(findVersionsList().props()).toMatchObject({
        canDestroy: true,
        count: packageVersions().length,
        isMutationLoading: false,
        packageId: 'gid://gitlab/Packages::Package/1',
        isRequestForwardingEnabled: true,
      });
    });

    describe('delete packages', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('exists and has the correct props', () => {
        expect(findDeletePackages().props('showSuccessAlert')).toBe(true);
        expect(findDeletePackages().props('refetchQueries')).toEqual([
          {
            query: getPackageVersionsQuery,
            variables: {
              first: 20,
              id: 'gid://gitlab/Packages::Package/1',
            },
          },
        ]);
      });

      it('deletePackages is bound to package-versions-list delete event', () => {
        findVersionsList().vm.$emit('delete', [{ id: 1 }]);

        expect(findDeletePackages().emitted('start')).toEqual([[]]);
      });

      it('start and end event set loading correctly', async () => {
        findDeletePackages().vm.$emit('start');

        await nextTick();

        expect(findVersionsList().props('isMutationLoading')).toBe(true);

        findDeletePackages().vm.$emit('end');

        await nextTick();

        expect(findVersionsList().props('isMutationLoading')).toBe(false);
      });
    });
  });

  describe('dependency links', () => {
    it('does not show the dependency links for a non nuget package', () => {
      createComponent();

      expect(findDependenciesCountBadge().exists()).toBe(false);
    });

    it('shows the dependencies tab with 0 count when a nuget package with no dependencies', async () => {
      createComponent({
        resolver: jest.fn().mockResolvedValue(
          packageDetailsQuery({
            extendPackage: {
              packageType: PACKAGE_TYPE_NUGET,
              dependencyLinks: { nodes: [] },
            },
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
            extendPackage: {
              packageType: PACKAGE_TYPE_NUGET,
            },
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
