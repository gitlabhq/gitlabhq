import { GlEmptyState, GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import stubChildren from 'helpers/stub_children';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '~/packages_and_registries/infrastructure_registry/details/constants';
import PackagesApp from '~/packages_and_registries/infrastructure_registry/details/components/app.vue';
import PackageFiles from '~/packages_and_registries/infrastructure_registry/details/components/package_files.vue';
import PackageHistory from '~/packages_and_registries/infrastructure_registry/details/components/package_history.vue';
import PackageListRow from '~/packages_and_registries/infrastructure_registry/shared/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import {
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  TRACKING_ACTIONS,
} from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';
import TerraformTitle from '~/packages_and_registries/infrastructure_registry/details/components/details_title.vue';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import Markdown from '~/vue_shared/components/markdown/markdown_content.vue';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { mavenPackage, mavenFiles, npmPackage, terraformModule } from '../../mock_data';

useMockLocationHelper();
jest.mock('~/alert');
jest.mock('~/api.js');

describe('PackagesApp', () => {
  let wrapper;
  const defaultProjectName = 'bar';

  const defaultProvide = {
    svgPath: 'empty-illustration',
    projectListUrl: 'project_url',
    canDelete: true,
  };

  function createComponent({
    packageEntity = mavenPackage,
    packageFiles = mavenFiles,
    projectName = defaultProjectName,
  } = {}) {
    wrapper = mount(PackagesApp, {
      propsData: {
        initialPackageEntity: packageEntity,
        initialPackageFiles: packageFiles,
      },
      provide: {
        ...defaultProvide,
        projectName,
      },
      stubs: {
        ...stubChildren(PackagesApp),
        TerraformTitle: false,
        TitleArea: false,
        GlButton: false,
        GlModal: false,
        GlTabs: false,
        GlTable: false,
        Markdown: stubComponent(Markdown),
      },
    });
  }

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const packageTitle = () => wrapper.findComponent(TerraformTitle);
  const emptyState = () => wrapper.findComponent(GlEmptyState);
  const deleteButton = () => wrapper.find('.js-delete-button');
  const findDeleteModal = () => wrapper.findComponent({ ref: 'deleteModal' });
  const findDeleteFileModal = () => wrapper.findComponent({ ref: 'deleteFileModal' });
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const versionsTab = () => findAllTabs().at(1);
  const packagesLoader = () => wrapper.findComponent(PackagesListLoader);
  const packagesVersionRows = () => wrapper.findAllComponents(PackageListRow);
  const noVersionsMessage = () => wrapper.find('[data-testid="no-versions-message"]');
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findTerraformInstallation = () => wrapper.findComponent(TerraformInstallation);
  const findPackageFiles = () => wrapper.findComponent(PackageFiles);
  const findReadmeTab = () => findAllTabs().at(2);
  const findMarkdown = () => wrapper.findComponent(Markdown);

  it('renders the app and displays the package title', () => {
    createComponent();

    expect(packageTitle().exists()).toBe(true);
    expect(packageTitle().props()).toMatchObject({
      packageEntity: mavenPackage,
      packageFiles: mavenFiles,
      packagePipeline: null,
    });
  });

  it('renders an empty state component when no an invalid package is passed as a prop', () => {
    createComponent({
      packageEntity: {},
    });

    expect(emptyState().exists()).toBe(true);
  });

  it('package history has the right props', () => {
    createComponent();
    expect(findPackageHistory().exists()).toBe(true);
    expect(findPackageHistory().props('packageEntity')).toEqual(mavenPackage);
    expect(findPackageHistory().props('projectName')).toEqual(defaultProjectName);
  });

  it('terraform installation exists', () => {
    createComponent({
      packageEntity: terraformModule,
    });

    expect(findTerraformInstallation().props()).toEqual({
      packageName: 'Test/system-22',
      packageVersion: '0.1',
    });
  });

  describe('deleting packages', () => {
    beforeEach(() => {
      createComponent();
      deleteButton().trigger('click');
    });

    it('shows the delete confirmation modal when delete is clicked', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });
  });

  describe('deleting package files', () => {
    it('shows the delete confirmation modal when delete is clicked', () => {
      createComponent();
      findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);

      expect(findDeleteFileModal().exists()).toBe(true);
    });
  });

  describe('versions', () => {
    const createPackageVersions = () => [
      { ...mavenPackage, id: 3, version: '3.0.0' },
      { ...mavenPackage, id: 4, version: '4.0.0' },
    ];

    const createDeferredVersionsRequest = () => {
      let resolveRequest;
      const promise = new Promise((resolve) => {
        resolveRequest = resolve;
      });

      return { promise, resolve: resolveRequest };
    };

    describe('api call', () => {
      beforeEach(() => {
        createComponent();
      });

      it('makes api request on first click of tab', async () => {
        const packageVersions = createPackageVersions();
        Api.projectPackage.mockResolvedValue({ data: { versions: packageVersions } });

        versionsTab().vm.$emit('click');
        await waitForPromises();

        expect(Api.projectPackage).toHaveBeenCalledWith(mavenPackage.project_id, mavenPackage.id);
      });
    });

    it('displays the loader while package versions are loading', async () => {
      const request = createDeferredVersionsRequest();
      Api.projectPackage.mockReturnValue(request.promise);
      createComponent();

      versionsTab().vm.$emit('click');
      await nextTick();

      expect(packagesLoader().exists()).toBe(true);

      request.resolve({ data: { versions: [] } });
      await waitForPromises();
    });

    it('displays the fetched versions in reverse order', async () => {
      const packageVersions = createPackageVersions();
      Api.projectPackage.mockResolvedValue({ data: { versions: packageVersions } });
      createComponent();

      versionsTab().vm.$emit('click');
      await waitForPromises();

      expect(packagesVersionRows()).toHaveLength(packageVersions.length);
      expect(packagesVersionRows().at(0).props('packageLink')).toBe('4');
    });

    it('displays the no versions message when there are none', () => {
      createComponent();

      expect(noVersionsMessage().exists()).toBe(true);
    });

    it('shows an alert when loading versions fails', async () => {
      Api.projectPackage.mockRejectedValue();
      createComponent();

      versionsTab().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: FETCH_PACKAGE_VERSIONS_ERROR,
        variant: VARIANT_WARNING,
      });
      expect(packagesLoader().exists()).toBe(false);
    });
  });

  describe('readme', () => {
    it('does not show tab when readme data does not exist', () => {
      createComponent({
        packageEntity: terraformModule,
      });

      const tabsContainingReadme = findAllTabs().filter(
        (tab) => tab.attributes('title') === 'Readme',
      );
      expect(tabsContainingReadme).toHaveLength(0);
    });

    describe('when readme data exists', () => {
      beforeEach(() => {
        createComponent({
          packageEntity: {
            ...terraformModule,
            terraform_module_metadatum: {
              fields: {
                root: {
                  readme: '# Header',
                },
              },
            },
          },
        });
      });

      it('renders tab', () => {
        expect(findReadmeTab().attributes('title')).toBe('Readme');
      });

      it('sets lazy attribute on tab', () => {
        expect(findReadmeTab().attributes('lazy')).toBeDefined();
      });

      it('renders readme data', () => {
        expect(findMarkdown().props('value')).toBe('# Header');
      });
    });
  });

  describe('tracking and delete', () => {
    describe('delete package', () => {
      it('calls the delete package API', async () => {
        Api.deleteProjectPackage.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(Api.deleteProjectPackage).toHaveBeenCalledWith(npmPackage.project_id, npmPackage.id);
      });

      it('calls window.replace with project url', async () => {
        Api.deleteProjectPackage.mockResolvedValue({ status: 204 });
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(window.location.replace).toHaveBeenCalledWith(
          'project_url?showSuccessDeleteAlert=true',
        );
      });

      it('does not redirect on delete failure', async () => {
        Api.deleteProjectPackage.mockRejectedValue(new Error('error'));
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(window.location.replace).not.toHaveBeenCalled();
      });

      it('creates an alert with the default error message', async () => {
        Api.deleteProjectPackage.mockRejectedValue(new Error('error'));
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
          variant: VARIANT_WARNING,
        });
      });

      it('creates an alert with the server error message', async () => {
        const serverMessage = 'Package is deletion protected.';
        const apiError = new Error('error');
        apiError.response = { data: { message: serverMessage } };
        Api.deleteProjectPackage.mockRejectedValue(apiError);
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('primary');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: serverMessage,
          variant: VARIANT_WARNING,
        });
      });
    });

    describe('delete file', () => {
      it('calls the delete package file API', async () => {
        Api.deleteProjectPackageFile.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);
        findDeleteFileModal().vm.$emit('primary');
        await waitForPromises();

        expect(Api.deleteProjectPackageFile).toHaveBeenCalledWith(
          npmPackage.project_id,
          npmPackage.id,
          mavenFiles[0].id,
        );
      });

      it('removes the deleted file and shows a success alert', async () => {
        Api.deleteProjectPackageFile.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);
        findDeleteFileModal().vm.$emit('primary');
        await waitForPromises();

        expect(findPackageFiles().props('packageFiles')).toEqual([mavenFiles[1]]);
        expect(createAlert).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
          variant: VARIANT_SUCCESS,
        });
      });

      it('creates an alert with the default error message', async () => {
        Api.deleteProjectPackageFile.mockRejectedValue();
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);
        findDeleteFileModal().vm.$emit('primary');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
          variant: VARIANT_WARNING,
        });
      });

      it('creates an alert with the server error message', async () => {
        const serverMessage = '403 Forbidden - Package is deletion protected.';
        const apiError = new Error('error');
        apiError.response = { data: { message: serverMessage } };
        Api.deleteProjectPackageFile.mockRejectedValue(apiError);
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);
        findDeleteFileModal().vm.$emit('primary');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: serverMessage,
          variant: VARIANT_WARNING,
        });
      });
    });

    describe('tracking', () => {
      let eventSpy;

      beforeEach(() => {
        eventSpy = mockTracking(undefined, undefined, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it(`delete button on delete modal call event with ${TRACKING_ACTIONS.DELETE_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.DELETE_PACKAGE,
          expect.any(Object),
        );
      });

      it(`canceling a package deletion tracks  ${TRACKING_ACTIONS.CANCEL_DELETE_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('canceled');

        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.CANCEL_DELETE_PACKAGE,
          expect.any(Object),
        );
      });

      it(`request a file deletion tracks  ${TRACKING_ACTIONS.REQUEST_DELETE_PACKAGE_FILE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);

        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.REQUEST_DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`confirming a file deletion tracks  ${TRACKING_ACTIONS.DELETE_PACKAGE_FILE}`, () => {
        Api.deleteProjectPackageFile.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', npmPackage);
        findDeleteFileModal().vm.$emit('primary');

        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`canceling a file deletion tracks  ${TRACKING_ACTIONS.CANCEL_DELETE_PACKAGE_FILE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', npmPackage);
        findDeleteFileModal().vm.$emit('canceled');

        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.CANCEL_DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`file download link call event with ${TRACKING_ACTIONS.PULL_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('download-file');
        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.PULL_PACKAGE,
          expect.any(Object),
        );
      });
    });
  });
});
