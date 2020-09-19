import Vuex from 'vuex';
import { last } from 'lodash';
import { GlTable, GlPagination, GlModal } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import Tracking from '~/tracking';
import PackagesList from '~/packages/list/components/packages_list.vue';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';
import PackagesListRow from '~/packages/shared/components/package_list_row.vue';
import * as SharedUtils from '~/packages/shared/utils';
import { TrackingActions } from '~/packages/shared/constants';
import { packageList } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_list', () => {
  let wrapper;
  let store;

  const EmptySlotStub = { name: 'empty-slot-stub', template: '<div>bar</div>' };

  const findPackagesListLoader = () => wrapper.find(PackagesListLoader);
  const findPackageListPagination = () => wrapper.find(GlPagination);
  const findPackageListDeleteModal = () => wrapper.find(GlModal);
  const findEmptySlot = () => wrapper.find(EmptySlotStub);
  const findPackagesListRow = () => wrapper.find(PackagesListRow);

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
      localVue,
      store,
      stubs: {
        ...stubChildren(PackagesList),
        GlTable,
        GlModal,
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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

    it('contains a modal component', () => {
      const sorting = findPackageListDeleteModal();
      expect(sorting.exists()).toBe(true);
    });
  });

  describe('when the user can destroy the package', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('setItemToBeDeleted sets itemToBeDeleted and open the modal', () => {
      const mockModalShow = jest.spyOn(wrapper.vm.$refs.packageListDeleteModal, 'show');
      const item = last(wrapper.vm.list);

      findPackagesListRow().vm.$emit('packageToDelete', item);

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.itemToBeDeleted).toEqual(item);
        expect(mockModalShow).toHaveBeenCalled();
      });
    });

    it('deleteItemConfirmation resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemConfirmation();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
    });

    it('deleteItemConfirmation emit package:delete', () => {
      const itemToBeDeleted = { id: 2 };
      wrapper.setData({ itemToBeDeleted });
      wrapper.vm.deleteItemConfirmation();
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.emitted('package:delete')[0]).toEqual([itemToBeDeleted]);
      });
    });

    it('deleteItemCanceled resets itemToBeDeleted', () => {
      wrapper.setData({ itemToBeDeleted: 1 });
      wrapper.vm.deleteItemCanceled();
      expect(wrapper.vm.itemToBeDeleted).toEqual(null);
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
    let eventSpy;
    let utilSpy;
    const category = 'foo';

    beforeEach(() => {
      mountComponent();
      eventSpy = jest.spyOn(Tracking, 'event');
      utilSpy = jest.spyOn(SharedUtils, 'packageTypeToTrackCategory').mockReturnValue(category);
      wrapper.setData({ itemToBeDeleted: { package_type: 'conan' } });
    });

    it('tracking category calls packageTypeToTrackCategory', () => {
      expect(wrapper.vm.tracking.category).toBe(category);
      expect(utilSpy).toHaveBeenCalledWith('conan');
    });

    it('deleteItemConfirmation calls event', () => {
      wrapper.vm.deleteItemConfirmation();
      expect(eventSpy).toHaveBeenCalledWith(
        category,
        TrackingActions.DELETE_PACKAGE,
        expect.any(Object),
      );
    });
  });
});
