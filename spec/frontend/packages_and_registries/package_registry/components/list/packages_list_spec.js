import { GlAlert, GlKeysetPagination, GlModal, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
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
  const GlModalStub = {
    name: GlModal.name,
    template: '<div><slot></slot></div>',
    methods: { show: jest.fn() },
  };

  const findPackagesListLoader = () => wrapper.findComponent(PackagesListLoader);
  const findPackageListPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPackageListDeleteModal = () => wrapper.findComponent(GlModalStub);
  const findEmptySlot = () => wrapper.findComponent(EmptySlotStub);
  const findPackagesListRow = () => wrapper.findComponent(PackagesListRow);
  const findErrorPackageAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(PackagesList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlModal: GlModalStub,
        GlSprintf,
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  beforeEach(() => {
    GlModalStub.methods.show.mockReset();
  });

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

    it('does not show the rows', () => {
      expect(findPackagesListRow().exists()).toBe(false);
    });

    it('does not show the pagination', () => {
      expect(findPackageListPagination().exists()).toBe(false);
    });
  });

  describe('when is not loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('does not show skeleton loader', () => {
      expect(findPackagesListLoader().exists()).toBe(false);
    });

    it('shows the rows', () => {
      expect(findPackagesListRow().exists()).toBe(true);
    });
  });

  describe('layout', () => {
    it('contains a pagination component', () => {
      mountComponent({ pageInfo: { hasPreviousPage: true } });

      expect(findPackageListPagination().exists()).toBe(true);
    });

    it('contains a modal component', () => {
      mountComponent();

      expect(findPackageListDeleteModal().exists()).toBe(true);
    });

    it('does not have an error alert displayed', () => {
      mountComponent();

      expect(findErrorPackageAlert().exists()).toBe(false);
    });
  });

  describe('when the user can destroy the package', () => {
    beforeEach(() => {
      mountComponent();
      findPackagesListRow().vm.$emit('packageToDelete', firstPackage);
      return nextTick();
    });

    it('deleting a package opens the modal', () => {
      expect(findPackageListDeleteModal().text()).toContain(firstPackage.name);
    });

    it('confirming on the modal emits package:delete', async () => {
      findPackageListDeleteModal().vm.$emit('ok');

      await nextTick();

      expect(wrapper.emitted('package:delete')[0]).toEqual([firstPackage]);
    });

    it('closing the modal resets itemToBeDeleted', async () => {
      // triggering the v-model
      findPackageListDeleteModal().vm.$emit('input', false);

      await nextTick();

      expect(findPackageListDeleteModal().text()).not.toContain(firstPackage.name);
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
      findPackageListPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev-page')).toEqual([[]]);
    });

    it('emits next-page events when the next event is fired', () => {
      findPackageListPagination().vm.$emit('next');

      expect(wrapper.emitted('next-page')).toEqual([[]]);
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
