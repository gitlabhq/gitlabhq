import { GlTable, GlPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import { last } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PackagesList from '~/packages_and_registries/infrastructure_registry/list/components/packages_list.vue';
import PackagesListRow from '~/packages_and_registries/infrastructure_registry/shared/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';
import { TRACKING_ACTIONS } from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';
import { packageList } from '../../mock_data';

Vue.use(Vuex);

describe('packages_list', () => {
  let wrapper;
  let store;

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>bar</div>' };

  const findPackagesListLoader = () => wrapper.findComponent(PackagesListLoader);
  const findPackageListPagination = () => wrapper.findComponent(GlPagination);
  const findPackageListDeleteModal = () => wrapper.findComponent(DeletePackageModal);
  const findEmptySlot = () => wrapper.findComponent(EmptySlotStub);
  const findPackagesListRow = () => wrapper.findComponent(PackagesListRow);

  const createStore = (isGroupPage, packages, isLoading) => {
    const state = {
      isLoading,
      packages,
      pagination: {
        perPage: 1,
        total: 1,
        page: 1,
      },
      config: {
        isGroupPage,
      },
      sorting: {
        orderBy: 'version',
        sort: 'desc',
      },
    };
    store = new Vuex.Store({
      state,
      getters: {
        getList: () => packages,
      },
    });
    store.dispatch = jest.fn();
  };

  const mountComponent = ({
    isGroupPage = false,
    packages = packageList,
    isLoading = false,
    ...options
  } = {}) => {
    createStore(isGroupPage, packages, isLoading);

    wrapper = mount(PackagesList, {
      store,
      stubs: {
        ...stubChildren(PackagesList),
        GlTable,
        DeletePackageModal,
      },
      ...options,
    });
  };

  describe('when is loading', () => {
    beforeEach(() => {
      mountComponent({
        packages: [],
        isLoading: true,
      });
    });

    it('shows skeleton loader when loading', () => {
      expect(findPackagesListLoader().exists()).toBe(true);
    });
  });

  describe('when is not loading', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('does not show skeleton loader when not loading', () => {
      expect(findPackagesListLoader().exists()).toBe(false);
    });
  });

  describe('layout', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('contains a pagination component', () => {
      const sorting = findPackageListPagination();
      expect(sorting.exists()).toBe(true);
    });

    it("doesn't contain a modal component", () => {
      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toBeNull();
    });
  });

  describe('when the user can destroy the package', () => {
    let itemToBeDeleted;

    beforeEach(async () => {
      mountComponent();
      itemToBeDeleted = last(packageList);
      await findPackagesListRow().vm.$emit('packageToDelete', itemToBeDeleted);
    });

    afterEach(() => {
      itemToBeDeleted = null;
    });

    it('passes itemToBeDeleted to the modal', () => {
      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toStrictEqual(itemToBeDeleted);
    });

    it('deleteItemConfirmation emit package:delete', async () => {
      await findPackageListDeleteModal().vm.$emit('ok');

      expect(wrapper.emitted('package:delete')[0]).toEqual([itemToBeDeleted]);
    });

    it.each(['ok', 'cancel'])('resets itemToBeDeleted when modal emits %s', async (event) => {
      await findPackageListDeleteModal().vm.$emit(event);

      expect(findPackageListDeleteModal().props('itemToBeDeleted')).toBeNull();
    });
  });

  describe('when the list is empty', () => {
    beforeEach(() => {
      mountComponent({
        packages: [],
        slots: {
          'empty-state': EmptySlotStub,
        },
      });
    });

    it('show the empty slot', () => {
      const emptySlot = findEmptySlot();
      expect(emptySlot.exists()).toBe(true);
    });
  });

  describe('pagination component', () => {
    let pagination;
    let modelEvent;

    beforeEach(() => {
      mountComponent();
      pagination = findPackageListPagination();
      // retrieve the event used by v-model, a more sturdy approach than hardcoding it
      modelEvent = pagination.vm.$options.model.event;
    });

    it('emits page:changed events when the page changes', () => {
      pagination.vm.$emit(modelEvent, 2);
      expect(wrapper.emitted('page:changed')).toEqual([[2]]);
    });
  });

  describe('tracking', () => {
    let trackingSpy = null;

    beforeEach(() => {
      mountComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('deleteItemConfirmation calls event', async () => {
      await findPackageListDeleteModal().vm.$emit('ok');

      expect(trackingSpy).toHaveBeenCalledWith(TRACK_CATEGORY, TRACKING_ACTIONS.DELETE_PACKAGE, {
        category: TRACK_CATEGORY,
      });
    });
  });
});
