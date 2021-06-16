import { GlEmptyState } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';

import AdditionalMetadata from '~/packages/details/components/additional_metadata.vue';
import PackagesApp from '~/packages/details/components/app.vue';
import DependencyRow from '~/packages/details/components/dependency_row.vue';
import InstallationCommands from '~/packages/details/components/installation_commands.vue';
import PackageFiles from '~/packages/details/components/package_files.vue';
import PackageHistory from '~/packages/details/components/package_history.vue';
import PackageTitle from '~/packages/details/components/package_title.vue';
import * as getters from '~/packages/details/store/getters';
import PackageListRow from '~/packages/shared/components/package_list_row.vue';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';
import { TrackingActions } from '~/packages/shared/constants';
import * as SharedUtils from '~/packages/shared/utils';
import Tracking from '~/tracking';

import {
  composerPackage,
  conanPackage,
  mavenPackage,
  mavenFiles,
  npmPackage,
  nugetPackage,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackagesApp', () => {
  let wrapper;
  let store;
  const fetchPackageVersions = jest.fn();
  const deletePackage = jest.fn();
  const deletePackageFile = jest.fn();
  const defaultProjectName = 'bar';
  const { location } = window;

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
        PackageTitle: false,
        TitleArea: false,
        GlButton: false,
        GlModal: false,
        GlTab: false,
        GlTabs: false,
        GlTable: false,
      },
    });
  }

  const packageTitle = () => wrapper.find(PackageTitle);
  const emptyState = () => wrapper.find(GlEmptyState);
  const deleteButton = () => wrapper.find('.js-delete-button');
  const findDeleteModal = () => wrapper.find({ ref: 'deleteModal' });
  const findDeleteFileModal = () => wrapper.find({ ref: 'deleteFileModal' });
  const versionsTab = () => wrapper.find('.js-versions-tab > a');
  const packagesLoader = () => wrapper.find(PackagesListLoader);
  const packagesVersionRows = () => wrapper.findAll(PackageListRow);
  const noVersionsMessage = () => wrapper.find('[data-testid="no-versions-message"]');
  const dependenciesTab = () => wrapper.find('.js-dependencies-tab > a');
  const dependenciesCountBadge = () => wrapper.find('[data-testid="dependencies-badge"]');
  const noDependenciesMessage = () => wrapper.find('[data-testid="no-dependencies-message"]');
  const dependencyRows = () => wrapper.findAll(DependencyRow);
  const findPackageHistory = () => wrapper.find(PackageHistory);
  const findAdditionalMetadata = () => wrapper.find(AdditionalMetadata);
  const findInstallationCommands = () => wrapper.find(InstallationCommands);
  const findPackageFiles = () => wrapper.find(PackageFiles);

  beforeEach(() => {
    delete window.location;
    window.location = { replace: jest.fn() };
  });

  afterEach(() => {
    wrapper.destroy();
    window.location = location;
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

  it('additional metadata has the right props', () => {
    createComponent();
    expect(findAdditionalMetadata().exists()).toBe(true);
    expect(findAdditionalMetadata().props('packageEntity')).toEqual(wrapper.vm.packageEntity);
  });

  it('installation commands has the right props', () => {
    createComponent();
    expect(findInstallationCommands().exists()).toBe(true);
    expect(findInstallationCommands().props('packageEntity')).toEqual(wrapper.vm.packageEntity);
  });

  it('hides the files table if package type is COMPOSER', () => {
    createComponent({ packageEntity: composerPackage });
    expect(findPackageFiles().exists()).toBe(false);
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

  describe('dependency links', () => {
    it('does not show the dependency links for a non nuget package', () => {
      createComponent();

      expect(dependenciesTab().exists()).toBe(false);
    });

    it('shows the dependencies tab with 0 count when a nuget package with no dependencies', () => {
      createComponent({
        packageEntity: {
          ...nugetPackage,
          dependency_links: [],
        },
      });

      return wrapper.vm.$nextTick(() => {
        const dependenciesBadge = dependenciesCountBadge();

        expect(dependenciesTab().exists()).toBe(true);
        expect(dependenciesBadge.exists()).toBe(true);
        expect(dependenciesBadge.text()).toBe('0');
        expect(noDependenciesMessage().exists()).toBe(true);
      });
    });

    it('renders the correct number of dependency rows for a nuget package', () => {
      createComponent({ packageEntity: nugetPackage });

      return wrapper.vm.$nextTick(() => {
        const dependenciesBadge = dependenciesCountBadge();

        expect(dependenciesTab().exists()).toBe(true);
        expect(dependenciesBadge.exists()).toBe(true);
        expect(dependenciesBadge.text()).toBe(nugetPackage.dependency_links.length.toString());
        expect(dependencyRows()).toHaveLength(nugetPackage.dependency_links.length);
      });
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
        createComponent({ packageEntity: conanPackage });
        expect(wrapper.vm.tracking.category).toBe(category);
        expect(utilSpy).toHaveBeenCalledWith('conan');
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
        createComponent({ packageEntity: conanPackage });

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
