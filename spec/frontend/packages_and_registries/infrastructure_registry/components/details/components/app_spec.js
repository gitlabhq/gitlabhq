import { GlEmptyState, GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import stubChildren from 'helpers/stub_children';
import PackagesApp from '~/packages_and_registries/infrastructure_registry/details/components/app.vue';
import PackageFiles from '~/packages_and_registries/infrastructure_registry/details/components/package_files.vue';
import PackageHistory from '~/packages_and_registries/infrastructure_registry/details/components/package_history.vue';
import * as getters from '~/packages_and_registries/infrastructure_registry/details/store/getters';
import PackageListRow from '~/packages_and_registries/infrastructure_registry/shared/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import { TRACKING_ACTIONS } from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';
import TerraformTitle from '~/packages_and_registries/infrastructure_registry/details/components/details_title.vue';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import Markdown from '~/vue_shared/components/markdown/markdown_content.vue';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { mavenPackage, mavenFiles, npmPackage, terraformModule } from '../../mock_data';

Vue.use(Vuex);

useMockLocationHelper();

describe('PackagesApp', () => {
  let wrapper;
  let store;
  const fetchPackageVersions = jest.fn();
  const deletePackage = jest.fn();
  const deletePackageFile = jest.fn();
  const defaultProjectName = 'bar';

  const defaultProvide = {
    svgPath: 'empty-illustration',
    projectListUrl: 'project_url',
    canDelete: true,
  };

  function createComponent({
    packageEntity = mavenPackage,
    packageFiles = mavenFiles,
    isLoading = false,
    projectName = defaultProjectName,
  } = {}) {
    store = new Vuex.Store({
      state: {
        isLoading,
        packageEntity,
        packageFiles,
      },
      actions: {
        deletePackage,
        fetchPackageVersions,
        deletePackageFile,
      },
      getters,
    });

    wrapper = mount(PackagesApp, {
      store,
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
    expect(findPackageHistory().props('packageEntity')).toEqual(wrapper.vm.packageEntity);
    expect(findPackageHistory().props('projectName')).toEqual(wrapper.vm.projectName);
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
    describe('api call', () => {
      beforeEach(() => {
        createComponent();
      });

      it('makes api request on first click of tab', () => {
        versionsTab().vm.$emit('click');

        expect(fetchPackageVersions).toHaveBeenCalled();
      });
    });

    it('displays the loader when state is loading', () => {
      createComponent({ isLoading: true });

      expect(packagesLoader().exists()).toBe(true);
    });

    it('displays the correct version count when the package has versions', () => {
      createComponent({ packageEntity: npmPackage });

      expect(packagesVersionRows()).toHaveLength(npmPackage.versions.length);
    });

    it('displays the no versions message when there are none', () => {
      createComponent();

      expect(noVersionsMessage().exists()).toBe(true);
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
      it('calls the proper vuex action', () => {
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        expect(deletePackage).toHaveBeenCalled();
      });

      it('calls window.replace with project url', async () => {
        deletePackage.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        await deletePackage();
        expect(window.location.replace).toHaveBeenCalledWith(
          'project_url?showSuccessDeleteAlert=true',
        );
      });
    });

    describe('delete file', () => {
      it('calls the proper vuex action', () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);
        findDeleteFileModal().vm.$emit('primary');

        expect(deletePackageFile).toHaveBeenCalled();
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
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', npmPackage);
        findDeleteFileModal().vm.$emit('primary');

        expect(eventSpy).toHaveBeenCalledWith(
          TRACK_CATEGORY,
          TRACKING_ACTIONS.REQUEST_DELETE_PACKAGE_FILE,
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
