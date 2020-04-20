import VueRouter from 'vue-router';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlPagination, GlSkeletonLoader, GlSprintf, GlAlert } from '@gitlab/ui';
import Tracking from '~/tracking';
import component from '~/registry/explorer/pages/list.vue';
import QuickstartDropdown from '~/registry/explorer/components/quickstart_dropdown.vue';
import GroupEmptyState from '~/registry/explorer/components/group_empty_state.vue';
import ProjectEmptyState from '~/registry/explorer/components/project_empty_state.vue';
import ProjectPolicyAlert from '~/registry/explorer/components/project_policy_alert.vue';
import store from '~/registry/explorer/stores/';
import { SET_MAIN_LOADING } from '~/registry/explorer/stores/mutation_types/';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
} from '~/registry/explorer/constants';
import { imagesListResponse } from '../mock_data';
import { GlModal, GlEmptyState } from '../stubs';
import { $toast } from '../../shared/mocks';

const localVue = createLocalVue();
localVue.use(VueRouter);

describe('List Page', () => {
  let wrapper;
  let dispatchSpy;

  const findDeleteBtn = () => wrapper.find({ ref: 'deleteImageButton' });
  const findDeleteModal = () => wrapper.find(GlModal);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);
  const findImagesList = () => wrapper.find({ ref: 'imagesList' });
  const findRowItems = () => wrapper.findAll({ ref: 'rowItem' });
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findDetailsLink = () => wrapper.find({ ref: 'detailsLink' });
  const findClipboardButton = () => wrapper.find({ ref: 'clipboardButton' });
  const findPagination = () => wrapper.find(GlPagination);
  const findQuickStartDropdown = () => wrapper.find(QuickstartDropdown);
  const findProjectEmptyState = () => wrapper.find(ProjectEmptyState);
  const findGroupEmptyState = () => wrapper.find(GroupEmptyState);
  const findProjectPolicyAlert = () => wrapper.find(ProjectPolicyAlert);
  const findDeleteAlert = () => wrapper.find(GlAlert);

  beforeEach(() => {
    wrapper = shallowMount(component, {
      localVue,
      store,
      stubs: {
        GlModal,
        GlEmptyState,
        GlSprintf,
      },
      mocks: {
        $toast,
      },
    });
    dispatchSpy = jest.spyOn(store, 'dispatch');
    store.dispatch('receiveImagesListSuccess', imagesListResponse);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Expiration policy notification', () => {
    it('shows up on project page', () => {
      expect(findProjectPolicyAlert().exists()).toBe(true);
    });
    it('does show up on group page', () => {
      store.dispatch('setInitialState', { isGroupPage: true });
      return wrapper.vm.$nextTick().then(() => {
        expect(findProjectPolicyAlert().exists()).toBe(false);
      });
    });
  });

  describe('connection error', () => {
    const config = {
      characterError: true,
      containersErrorImage: 'foo',
      helpPagePath: 'bar',
    };

    beforeAll(() => {
      store.dispatch('setInitialState', config);
    });

    afterAll(() => {
      store.dispatch('setInitialState', {});
    });

    it('should show an empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('empty state should have an svg-path', () => {
      expect(findEmptyState().attributes('svg-path')).toBe(config.containersErrorImage);
    });

    it('empty state should have a description', () => {
      expect(findEmptyState().html()).toContain('connection error');
    });

    it('should not show the loading or default state', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findImagesList().exists()).toBe(false);
    });
  });

  describe('isLoading is true', () => {
    beforeAll(() => store.commit(SET_MAIN_LOADING, true));

    afterAll(() => store.commit(SET_MAIN_LOADING, false));

    it('shows the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      expect(findImagesList().exists()).toBe(false);
    });

    it('quick start is not visible', () => {
      expect(findQuickStartDropdown().exists()).toBe(false);
    });
  });

  describe('list is empty', () => {
    beforeEach(() => {
      store.dispatch('receiveImagesListSuccess', { data: [] });
    });

    it('quick start is not visible', () => {
      expect(findQuickStartDropdown().exists()).toBe(false);
    });

    it('project empty state is visible', () => {
      expect(findProjectEmptyState().exists()).toBe(true);
    });

    describe('is group page is true', () => {
      beforeAll(() => {
        store.dispatch('setInitialState', { isGroupPage: true });
      });

      afterAll(() => {
        store.dispatch('setInitialState', { isGroupPage: undefined });
      });

      it('group empty state is visible', () => {
        expect(findGroupEmptyState().exists()).toBe(true);
      });

      it('quick start is not visible', () => {
        expect(findQuickStartDropdown().exists()).toBe(false);
      });
    });
  });

  describe('list is not empty', () => {
    it('quick start is visible', () => {
      expect(findQuickStartDropdown().exists()).toBe(true);
    });

    describe('listElement', () => {
      let listElements;
      let firstElement;

      beforeEach(() => {
        listElements = findRowItems();
        [firstElement] = store.state.images;
      });

      it('contains one list element for each image', () => {
        expect(listElements.length).toBe(store.state.images.length);
      });

      it('contains a link to the details page', () => {
        const link = findDetailsLink();
        expect(link.html()).toContain(firstElement.path);
        expect(link.props('to').name).toBe('details');
      });

      it('contains a clipboard button', () => {
        const button = findClipboardButton();
        expect(button.exists()).toBe(true);
        expect(button.props('text')).toBe(firstElement.location);
        expect(button.props('title')).toBe(firstElement.location);
      });

      describe('delete image', () => {
        it('should be possible to delete a repo', () => {
          const deleteBtn = findDeleteBtn();
          expect(deleteBtn.exists()).toBe(true);
        });

        it('should call deleteItem when confirming deletion', () => {
          dispatchSpy.mockResolvedValue();
          findDeleteBtn().vm.$emit('click');
          expect(wrapper.vm.itemToDelete).not.toEqual({});
          findDeleteModal().vm.$emit('ok');
          expect(store.dispatch).toHaveBeenCalledWith(
            'requestDeleteImage',
            wrapper.vm.itemToDelete,
          );
        });

        it('should show a success alert when delete request is successful', () => {
          dispatchSpy.mockResolvedValue();
          findDeleteBtn().vm.$emit('click');
          expect(wrapper.vm.itemToDelete).not.toEqual({});
          return wrapper.vm.handleDeleteImage().then(() => {
            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_SUCCESS_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });
        });

        it('should show an error alert when delete request fails', () => {
          dispatchSpy.mockRejectedValue();
          findDeleteBtn().vm.$emit('click');
          expect(wrapper.vm.itemToDelete).not.toEqual({});
          return wrapper.vm.handleDeleteImage().then(() => {
            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_ERROR_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });
        });
      });

      describe('pagination', () => {
        it('exists', () => {
          expect(findPagination().exists()).toBe(true);
        });

        it('is wired to the correct pagination props', () => {
          const pagination = findPagination();
          expect(pagination.props('perPage')).toBe(store.state.pagination.perPage);
          expect(pagination.props('totalItems')).toBe(store.state.pagination.total);
          expect(pagination.props('value')).toBe(store.state.pagination.page);
        });

        it('fetch the data from the API when the v-model changes', () => {
          dispatchSpy.mockReturnValue();
          wrapper.setData({ currentPage: 2 });
          return wrapper.vm.$nextTick().then(() => {
            expect(store.dispatch).toHaveBeenCalledWith('requestImagesList', { page: 2 });
          });
        });
      });
    });

    describe('modal', () => {
      it('exists', () => {
        expect(findDeleteModal().exists()).toBe(true);
      });

      it('contains a description with the path of the item to delete', () => {
        wrapper.setData({ itemToDelete: { path: 'foo' } });
        return wrapper.vm.$nextTick().then(() => {
          expect(findDeleteModal().html()).toContain('foo');
        });
      });
    });

    describe('tracking', () => {
      const testTrackingCall = action => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, action, {
          label: 'registry_repository_delete',
        });
      };

      beforeEach(() => {
        jest.spyOn(Tracking, 'event');
        dispatchSpy.mockResolvedValue();
      });

      it('send an event when delete button is clicked', () => {
        const deleteBtn = findDeleteBtn();
        deleteBtn.vm.$emit('click');
        testTrackingCall('click_button');
      });

      it('send an event when cancel is pressed on modal', () => {
        const deleteModal = findDeleteModal();
        deleteModal.vm.$emit('cancel');
        testTrackingCall('cancel_delete');
      });

      it('send an event when confirm is clicked on modal', () => {
        const deleteModal = findDeleteModal();
        deleteModal.vm.$emit('ok');
        testTrackingCall('confirm_delete');
      });
    });
  });
});
