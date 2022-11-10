import { GlAlert, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import PackagesList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import Tracking from '~/tracking';
import { packageData } from '../../mock_data';

describe('packages_list', () => {
  let wrapper;

  const firstPackage = packageData();
  const secondPackage = {
    ...packageData(),
    id: 'gid://gitlab/Packages::Package/112',
    name: 'second-package',
  };
  const errorPackage = {
    ...packageData(),
    id: 'gid://gitlab/Packages::Package/121',
    status: 'ERROR',
    name: 'error package',
  };

  const defaultProps = {
    list: [firstPackage, secondPackage],
    isLoading: false,
    pageInfo: {},
  };

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>bar</div>' };

  const findPackagesListLoader = () => wrapper.findComponent(PackagesListLoader);
  const findPackageListDeleteModal = () => wrapper.findComponent(DeletePackageModal);
  const findEmptySlot = () => wrapper.findComponent(EmptySlotStub);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findPackagesListRow = () => wrapper.findComponent(PackagesListRow);
  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(PackagesList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        DeletePackageModal,
        GlSprintf,
        RegistryList,
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when is loading', () => {
    beforeEach(() => {
      mountComponent({ isLoading: true });
    });

    it('shows skeleton loader', () => {
      expect(findPackagesListLoader().exists()).toBe(true);
    });

    it('does not show the registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('does not show the rows', () => {
      expect(findPackagesListRow().exists()).toBe(false);
    });
  });

  describe('when is not loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('does not show skeleton loader', () => {
      expect(findPackagesListLoader().exists()).toBe(false);
    });

    it('shows the registry list', () => {
      expect(findRegistryList().exists()).toBe(true);
    });

    it('shows the registry list with the right props', () => {
      expect(findRegistryList().props()).toMatchObject({
        items: defaultProps.list,
        pagination: defaultProps.pageInfo,
        isLoading: false,
        hiddenDelete: true,
      });
    });

    it('shows the rows', () => {
      expect(findPackagesListRow().exists()).toBe(true);
    });
  });

  describe('layout', () => {
    it("doesn't contain a visible modal component", () => {
      mountComponent();

      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toBeNull();
    });

    it('does not have an error alert displayed', () => {
      mountComponent();

      expect(findErrorPackageAlert().exists()).toBe(false);
    });
  });

  describe('when the user can destroy the package', () => {
    beforeEach(async () => {
      mountComponent();
      await findPackagesListRow().vm.$emit('packageToDelete', firstPackage);
    });

    it('passes itemToBeDeleted to the modal', () => {
      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toStrictEqual(firstPackage);
    });

    it('emits package:delete when modal confirms', async () => {
      await findPackageListDeleteModal().vm.$emit('ok');

      expect(wrapper.emitted('package:delete')[0]).toEqual([firstPackage]);
    });

    it.each(['ok', 'cancel'])('resets itemToBeDeleted when modal emits %s', async (event) => {
      await findPackageListDeleteModal().vm.$emit(event);

      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toBeNull();
    });
  });

  describe('when an error package is present', () => {
    beforeEach(() => {
      mountComponent({ list: [firstPackage, errorPackage] });

      return nextTick();
    });

    it('should display an alert message', () => {
      expect(findErrorPackageAlert().exists()).toBe(true);
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing a error package package',
      );
      expect(findErrorPackageAlert().text()).toBe(
        'There was a timeout and the package was not published. Delete this package and try again.',
      );
    });

    it('should display the deletion modal when clicked on the confirm button', async () => {
      findErrorPackageAlert().vm.$emit('primaryAction');

      await nextTick();

      expect(findPackageListDeleteModal().text()).toContain(errorPackage.name);
    });
  });

  describe('when the list is empty', () => {
    beforeEach(() => {
      mountComponent({ list: [] });
    });

    it('show the empty slot', () => {
      const emptySlot = findEmptySlot();
      expect(emptySlot.exists()).toBe(true);
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      mountComponent({ pageInfo: { hasPreviousPage: true } });
    });

    it('emits prev-page events when the prev event is fired', () => {
      findRegistryList().vm.$emit('prev-page');

      expect(wrapper.emitted('prev-page')).toHaveLength(1);
    });

    it('emits next-page events when the next event is fired', () => {
      findRegistryList().vm.$emit('next-page');

      expect(wrapper.emitted('next-page')).toHaveLength(1);
    });
  });

  describe('tracking', () => {
    let eventSpy;
    const category = 'UI::NpmPackages';

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      mountComponent();
      findPackagesListRow().vm.$emit('packageToDelete', firstPackage);
      return nextTick();
    });

    it('requesting the delete tracks the right action', () => {
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
        expect.any(Object),
      );
    });

    it('confirming delete tracks the right action', () => {
      findPackageListDeleteModal().vm.$emit('ok');

      expect(eventSpy).toHaveBeenCalledWith(
        category,
        DELETE_PACKAGE_TRACKING_ACTION,
        expect.any(Object),
      );
    });

    it('canceling delete tracks the right action', () => {
      findPackageListDeleteModal().vm.$emit('cancel');

      expect(eventSpy).toHaveBeenCalledWith(
        category,
        CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
        expect.any(Object),
      );
    });
  });
});
