import { GlAlert, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGES_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGES_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGES_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import PackagesList from '~/packages_and_registries/package_registry/components/list/packages_list.vue';
import Tracking from '~/tracking';
import { defaultPackageGroupSettings, packageData } from '../../mock_data';

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
    groupSettings: defaultPackageGroupSettings,
  };

  const defaultProvide = {
    canDeletePackages: true,
  };

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>bar</div>' };

  const findPackagesListLoader = () => wrapper.findComponent(PackagesListLoader);
  const findEmptySlot = () => wrapper.findComponent(EmptySlotStub);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findPackagesListRow = () => wrapper.findComponent(PackagesListRow);
  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);
  const findDeletePackagesModal = () => wrapper.findComponent(DeleteModal);

  const showMock = jest.fn();

  const mountComponent = ({ props = {}, provide = defaultProvide } = {}) => {
    wrapper = shallowMountExtended(PackagesList, {
      provide,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        DeleteModal: stubComponent(DeleteModal, {
          methods: {
            show: showMock,
          },
        }),
        GlSprintf,
        RegistryList,
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  describe('when is loading', () => {
    beforeEach(() => {
      mountComponent({ props: { isLoading: true } });
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
        title: '2 packages',
        items: defaultProps.list,
        hiddenDelete: false,
        isLoading: false,
      });
    });

    it('shows the rows', () => {
      expect(findPackagesListRow().exists()).toBe(true);
    });
  });

  describe('layout', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('modal component is not shown', () => {
      expect(showMock).not.toHaveBeenCalled();
    });

    it('modal component props is empty', () => {
      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toEqual([]);
      expect(findDeletePackagesModal().props('showRequestForwardingContent')).toBe(false);
    });

    it('does not have an error alert displayed', () => {
      expect(findErrorPackageAlert().exists()).toBe(false);
    });
  });

  describe('when the user does not have permission to destroy packages', () => {
    beforeEach(() => {
      mountComponent({ provide: { canDeletePackages: false } });
    });

    it('sets the hidden delete prop of registry list to true', () => {
      expect(findRegistryList().props('hiddenDelete')).toBe(true);
    });
  });

  describe.each`
    description                                                               | finderFunction         | deletePayload
    ${'when the user can destroy the package'}                                | ${findPackagesListRow} | ${firstPackage}
    ${'when the user can bulk destroy packages and deletes only one package'} | ${findRegistryList}    | ${[firstPackage]}
  `('$description', ({ finderFunction, deletePayload }) => {
    let eventSpy;
    const category = 'UI::NpmPackages';

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      mountComponent();
      finderFunction().vm.$emit('delete', deletePayload);
    });

    it('passes itemsToBeDeleted to the modal', () => {
      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual([firstPackage]);
    });

    it('requesting delete tracks the right action', () => {
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
        expect.any(Object),
      );
    });

    it('modal component is shown', () => {
      expect(showMock).toHaveBeenCalledTimes(1);
    });

    describe('when modal confirms', () => {
      beforeEach(() => {
        findDeletePackagesModal().vm.$emit('confirm');
      });

      it('emits delete when modal confirms', () => {
        expect(wrapper.emitted('delete')[0][0]).toEqual([firstPackage]);
      });

      it('tracks the right action', () => {
        expect(eventSpy).toHaveBeenCalledWith(
          category,
          DELETE_PACKAGE_TRACKING_ACTION,
          expect.any(Object),
        );
      });
    });

    it.each(['confirm', 'cancel'])('resets itemsToBeDeleted when modal emits %s', async (event) => {
      await findDeletePackagesModal().vm.$emit(event);

      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toEqual([]);
    });

    it('canceling delete tracks the right action', () => {
      findDeletePackagesModal().vm.$emit('cancel');

      expect(eventSpy).toHaveBeenCalledWith(
        category,
        CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
        expect.any(Object),
      );
    });
  });

  describe('when the user can bulk destroy packages', () => {
    let eventSpy;
    const items = [firstPackage, secondPackage];

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      mountComponent();
      findRegistryList().vm.$emit('delete', items);
    });

    it('passes itemsToBeDeleted to the modal', () => {
      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual(items);
      expect(wrapper.emitted('delete')).toBeUndefined();
    });

    it('requesting delete tracks the right action', () => {
      expect(eventSpy).toHaveBeenCalledWith(
        undefined,
        REQUEST_DELETE_PACKAGES_TRACKING_ACTION,
        expect.any(Object),
      );
    });

    describe('when modal confirms', () => {
      beforeEach(() => {
        findDeletePackagesModal().vm.$emit('confirm');
      });

      it('emits delete event', () => {
        expect(wrapper.emitted('delete')[0]).toEqual([items]);
      });

      it('tracks the right action', () => {
        expect(eventSpy).toHaveBeenCalledWith(
          undefined,
          DELETE_PACKAGES_TRACKING_ACTION,
          expect.any(Object),
        );
      });
    });

    it.each(['confirm', 'cancel'])('resets itemsToBeDeleted when modal emits %s', async (event) => {
      await findDeletePackagesModal().vm.$emit(event);

      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toEqual([]);
    });

    it('canceling delete tracks the right action', () => {
      findDeletePackagesModal().vm.$emit('cancel');

      expect(eventSpy).toHaveBeenCalledWith(
        undefined,
        CANCEL_DELETE_PACKAGES_TRACKING_ACTION,
        expect.any(Object),
      );
    });
  });

  describe('when an error package is present', () => {
    beforeEach(() => {
      mountComponent({ props: { list: [firstPackage, errorPackage] } });

      return nextTick();
    });

    it('should display an alert with default body message', () => {
      expect(findErrorPackageAlert().exists()).toBe(true);
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing a error package package',
      );
      expect(findErrorPackageAlert().text()).toBe(
        'There was a timeout and the package was not published. Delete this package and try again.',
      );
    });

    it('should display alert body with message set in `statusMessage`', async () => {
      mountComponent({
        props: { list: [firstPackage, { ...errorPackage, statusMessage: 'custom error message' }] },
      });

      await nextTick();

      expect(findErrorPackageAlert().exists()).toBe(true);
      expect(findErrorPackageAlert().props('title')).toBe(
        'There was an error publishing a error package package',
      );
      expect(findErrorPackageAlert().text()).toBe('custom error message');
    });

    it('should display the deletion modal when clicked on the confirm button', async () => {
      findErrorPackageAlert().vm.$emit('primaryAction');

      await nextTick();

      expect(showMock).toHaveBeenCalledTimes(1);

      expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual([errorPackage]);
    });
  });

  describe('when the list is empty', () => {
    beforeEach(() => {
      mountComponent({ props: { list: [] } });
    });

    it('show the empty slot', () => {
      const emptySlot = findEmptySlot();
      expect(emptySlot.exists()).toBe(true);
    });
  });
});
