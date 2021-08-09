import { GlEmptyState, GlModal } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';

import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import PackagesApp from '~/packages_and_registries/package_registry/components/details/app.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import {
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  DELETE_PACKAGE_ERROR_MESSAGE,
} from '~/packages_and_registries/package_registry/constants';
import destroyPackageMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package.mutation.graphql';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import {
  packageDetailsQuery,
  packageData,
  emptyPackageDetailsQuery,
  packageDestroyMutation,
  packageDestroyMutationError,
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
  } = {}) {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getPackageDetails, resolver],
      [destroyPackageMutation, mutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(PackagesApp, {
      localVue,
      apolloProvider,
      provide,
      stubs: { PackageTitle },
    });
  }

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findPackageTitle = () => wrapper.findComponent(PackageTitle);
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findAdditionalMetadata = () => wrapper.findComponent(AdditionalMetadata);
  const findInstallationCommands = () => wrapper.findComponent(InstallationCommands);
  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findByTestId('delete-package');

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
});
