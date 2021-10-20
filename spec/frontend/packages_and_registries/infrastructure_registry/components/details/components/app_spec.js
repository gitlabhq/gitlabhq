import { GlEmptyState } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import stubChildren from 'helpers/stub_children';

import PackagesApp from '~/packages_and_registries/infrastructure_registry/details/components/app.vue';
import PackageFiles from '~/packages_and_registries/infrastructure_registry/details/components/package_files.vue';
import PackageHistory from '~/packages_and_registries/infrastructure_registry/details/components/package_history.vue';
import * as getters from '~/packages_and_registries/infrastructure_registry/details/store/getters';
import PackageListRow from '~/packages/shared/components/package_list_row.vue';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';
import { TrackingActions } from '~/packages/shared/constants';
import * as SharedUtils from '~/packages/shared/utils';
import TerraformTitle from '~/packages_and_registries/infrastructure_registry/details/components/details_title.vue';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import Tracking from '~/tracking';

import { mavenPackage, mavenFiles, npmPackage } from 'jest/packages/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

useMockLocationHelper();

describe('PackagesApp', () => {
  let wrapper;
  let store;
  const fetchPackageVersions = jest.fn();
  const deletePackage = jest.fn();
  const deletePackageFile = jest.fn();
  const defaultProjectName = 'bar';

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
        canDelete: true,
        emptySvgPath: 'empty-illustration',
        npmPath: 'foo',
        npmHelpPath: 'foo',
        projectName,
        projectListUrl: 'project_url',
        groupListUrl: 'group_url',
      },
      actions: {
        deletePackage,
        fetchPackageVersions,
        deletePackageFile,
      },
      getters,
    });

    wrapper = mount(PackagesApp, {
      localVue,
      store,
      stubs: {
        ...stubChildren(PackagesApp),
        TerraformTitle: false,
        TitleArea: false,
        GlButton: false,
        GlModal: false,
        GlTab: false,
        GlTabs: false,
        GlTable: false,
      },
    });
  }

  const packageTitle = () => wrapper.findComponent(TerraformTitle);
  const emptyState = () => wrapper.findComponent(GlEmptyState);
  const deleteButton = () => wrapper.find('.js-delete-button');
  const findDeleteModal = () => wrapper.find({ ref: 'deleteModal' });
  const findDeleteFileModal = () => wrapper.find({ ref: 'deleteFileModal' });
  const versionsTab = () => wrapper.find('.js-versions-tab > a');
  const packagesLoader = () => wrapper.findComponent(PackagesListLoader);
  const packagesVersionRows = () => wrapper.findAllComponents(PackageListRow);
  const noVersionsMessage = () => wrapper.find('[data-testid="no-versions-message"]');
  const findPackageHistory = () => wrapper.findComponent(PackageHistory);
  const findTerraformInstallation = () => wrapper.findComponent(TerraformInstallation);
  const findPackageFiles = () => wrapper.findComponent(PackageFiles);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the app and displays the package title', async () => {
    createComponent();

    await nextTick();

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
    createComponent();

    expect(findTerraformInstallation().exists()).toBe(true);
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
        versionsTab().trigger('click');

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

  describe('tracking and delete', () => {
    describe('delete package', () => {
      const originalReferrer = document.referrer;
      const setReferrer = (value = defaultProjectName) => {
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

      it('calls the proper vuex action', () => {
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        expect(deletePackage).toHaveBeenCalled();
      });

      it('when referrer contains project name calls window.replace with project url', async () => {
        setReferrer();
        deletePackage.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        await deletePackage();
        expect(window.location.replace).toHaveBeenCalledWith(
          'project_url?showSuccessDeleteAlert=true',
        );
      });

      it('when referrer does not contain project name calls window.replace with group url', async () => {
        setReferrer('baz');
        deletePackage.mockResolvedValue();
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        await deletePackage();
        expect(window.location.replace).toHaveBeenCalledWith(
          'group_url?showSuccessDeleteAlert=true',
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
      let utilSpy;
      const category = 'foo';

      beforeEach(() => {
        eventSpy = jest.spyOn(Tracking, 'event');
        utilSpy = jest.spyOn(SharedUtils, 'packageTypeToTrackCategory').mockReturnValue(category);
      });

      it('tracking category calls packageTypeToTrackCategory', () => {
        createComponent({ packageEntity: npmPackage });
        expect(wrapper.vm.tracking.category).toBe(category);
        expect(utilSpy).toHaveBeenCalledWith('npm');
      });

      it(`delete button on delete modal call event with ${TrackingActions.DELETE_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });
        findDeleteModal().vm.$emit('primary');
        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.DELETE_PACKAGE,
          expect.any(Object),
        );
      });

      it(`canceling a package deletion tracks  ${TrackingActions.CANCEL_DELETE_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findDeleteModal().vm.$emit('canceled');

        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.CANCEL_DELETE_PACKAGE,
          expect.any(Object),
        );
      });

      it(`request a file deletion tracks  ${TrackingActions.REQUEST_DELETE_PACKAGE_FILE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', mavenFiles[0]);

        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.REQUEST_DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`confirming a file deletion tracks  ${TrackingActions.DELETE_PACKAGE_FILE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', npmPackage);
        findDeleteFileModal().vm.$emit('primary');

        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.REQUEST_DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`canceling a file deletion tracks  ${TrackingActions.CANCEL_DELETE_PACKAGE_FILE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('delete-file', npmPackage);
        findDeleteFileModal().vm.$emit('canceled');

        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.CANCEL_DELETE_PACKAGE_FILE,
          expect.any(Object),
        );
      });

      it(`file download link call event with ${TrackingActions.PULL_PACKAGE}`, () => {
        createComponent({ packageEntity: npmPackage });

        findPackageFiles().vm.$emit('download-file');
        expect(eventSpy).toHaveBeenCalledWith(
          category,
          TrackingActions.PULL_PACKAGE,
          expect.any(Object),
        );
      });
    });
  });
});
