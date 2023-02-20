import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import Tracking from '~/tracking';
import {
  CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import { packageData } from '../../mock_data';

describe('PackageVersionsList', () => {
  let wrapper;

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>empty message</div>' };
  const packageList = [
    packageData({
      name: 'version 1',
    }),
    packageData({
      id: `gid://gitlab/Packages::Package/112`,
      name: 'version 2',
    }),
  ];

  const uiElements = {
    findLoader: () => wrapper.findComponent(PackagesListLoader),
    findRegistryList: () => wrapper.findComponent(RegistryList),
    findEmptySlot: () => wrapper.findComponent(EmptySlotStub),
    findListRow: () => wrapper.findAllComponents(VersionRow),
    findDeletePackagesModal: () => wrapper.findComponent(DeleteModal),
  };
  const mountComponent = (props) => {
    wrapper = shallowMountExtended(PackageVersionsList, {
      propsData: {
        versions: packageList,
        pageInfo: {},
        isLoading: false,
        ...props,
      },
      stubs: {
        RegistryList,
        DeleteModal: stubComponent(DeleteModal, {
          methods: {
            show: jest.fn(),
          },
        }),
      },
      slots: {
        'empty-state': EmptySlotStub,
      },
    });
  };

  describe('when list is loading', () => {
    beforeEach(() => {
      mountComponent({ isLoading: true, versions: [] });
    });
    it('displays loader', () => {
      expect(uiElements.findLoader().exists()).toBe(true);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
    });
  });

  describe('when list is loaded and has no data', () => {
    beforeEach(() => {
      mountComponent({ isLoading: false, versions: [] });
    });

    it('displays empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(true);
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display rows', () => {
      expect(uiElements.findListRow().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(uiElements.findRegistryList().exists()).toBe(false);
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('displays package registry list', () => {
      expect(uiElements.findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(uiElements.findRegistryList().props()).toMatchObject({
        items: packageList,
        pagination: {},
        isLoading: false,
        hiddenDelete: true,
      });
    });

    it('displays package version rows', () => {
      expect(uiElements.findListRow().exists()).toEqual(true);
      expect(uiElements.findListRow()).toHaveLength(packageList.length);
    });

    it('binds the correct props', () => {
      expect(uiElements.findListRow().at(0).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageList[0]),
      });

      expect(uiElements.findListRow().at(1).props()).toMatchObject({
        packageEntity: expect.objectContaining(packageList[1]),
      });
    });

    it('does not display loader', () => {
      expect(uiElements.findLoader().exists()).toBe(false);
    });

    it('does not display empty slot message', () => {
      expect(uiElements.findEmptySlot().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    beforeEach(() => {
      mountComponent({ pageInfo: { hasNextPage: true } });
    });

    it('emits prev-page event when registry list emits prev event', () => {
      uiElements.findRegistryList().vm.$emit('prev-page');

      expect(wrapper.emitted('prev-page')).toHaveLength(1);
    });

    it('emits next-page when registry list emits next event', () => {
      uiElements.findRegistryList().vm.$emit('next-page');

      expect(wrapper.emitted('next-page')).toHaveLength(1);
    });
  });

  describe('when the user can bulk destroy versions', () => {
    let eventSpy;
    const { findDeletePackagesModal, findRegistryList } = uiElements;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      mountComponent({ canDestroy: true });
    });

    it('binds the right props', () => {
      expect(uiElements.findRegistryList().props()).toMatchObject({
        items: packageList,
        pagination: {},
        isLoading: false,
        hiddenDelete: false,
        title: '2 versions',
      });
    });

    describe('upon deletion', () => {
      beforeEach(() => {
        findRegistryList().vm.$emit('delete', packageList);
      });

      it('passes itemsToBeDeleted to the modal', () => {
        expect(findDeletePackagesModal().props('itemsToBeDeleted')).toStrictEqual(packageList);
        expect(wrapper.emitted('delete')).toBeUndefined();
      });

      it('requesting delete tracks the right action', () => {
        expect(eventSpy).toHaveBeenCalledWith(
          undefined,
          REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
          expect.any(Object),
        );
      });

      describe('when modal confirms', () => {
        beforeEach(() => {
          findDeletePackagesModal().vm.$emit('confirm');
        });

        it('emits delete event', () => {
          expect(wrapper.emitted('delete')[0]).toEqual([packageList]);
        });

        it('tracks the right action', () => {
          expect(eventSpy).toHaveBeenCalledWith(
            undefined,
            DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
            expect.any(Object),
          );
        });
      });

      it.each(['confirm', 'cancel'])(
        'resets itemsToBeDeleted when modal emits %s',
        async (event) => {
          await findDeletePackagesModal().vm.$emit(event);

          expect(findDeletePackagesModal().props('itemsToBeDeleted')).toHaveLength(0);
        },
      );

      it('canceling delete tracks the right action', () => {
        findDeletePackagesModal().vm.$emit('cancel');

        expect(eventSpy).toHaveBeenCalledWith(
          undefined,
          CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
          expect.any(Object),
        );
      });
    });
  });
});
