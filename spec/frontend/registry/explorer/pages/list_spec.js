import VueRouter from 'vue-router';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlPagination, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Tracking from '~/tracking';
import component from '~/registry/explorer/pages/list.vue';
import store from '~/registry/explorer/stores/';
import { SET_MAIN_LOADING } from '~/registry/explorer/stores/mutation_types/';
import { imagesListResponse } from '../mock_data';
import { GlModal, GlEmptyState } from '../stubs';

const localVue = createLocalVue();
localVue.use(VueRouter);

describe('List Page', () => {
  let wrapper;
  let dispatchSpy;

  const findDeleteBtn = () => wrapper.find({ ref: 'deleteImageButton' });
  const findDeleteModal = () => wrapper.find(GlModal);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findImagesList = () => wrapper.find({ ref: 'imagesList' });
  const findRowItems = () => wrapper.findAll({ ref: 'rowItem' });
  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findDetailsLink = () => wrapper.find({ ref: 'detailsLink' });
  const findClipboardButton = () => wrapper.find({ ref: 'clipboardButton' });
  const findPagination = () => wrapper.find(GlPagination);

  beforeEach(() => {
    wrapper = shallowMount(component, {
      localVue,
      store,
      stubs: {
        GlModal,
        GlEmptyState,
        GlSprintf,
      },
    });
    dispatchSpy = jest.spyOn(store, 'dispatch');
    store.dispatch('receiveImagesListSuccess', imagesListResponse);
  });

  afterEach(() => {
    wrapper.destroy();
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
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findImagesList().exists()).toBe(false);
    });
  });

  describe('when isLoading is true', () => {
    beforeAll(() => store.commit(SET_MAIN_LOADING, true));

    afterAll(() => store.commit(SET_MAIN_LOADING, false));

    it('shows the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      expect(findImagesList().exists()).toBe(false);
    });
  });

  describe('list', () => {
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
          const itemToDelete = wrapper.vm.images[0];
          wrapper.setData({ itemToDelete });
          findDeleteModal().vm.$emit('ok');
          return wrapper.vm.$nextTick().then(() => {
            expect(store.dispatch).toHaveBeenCalledWith(
              'requestDeleteImage',
              itemToDelete.destroy_path,
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
        dispatchSpy.mockReturnValue();
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
        dispatchSpy.mockReturnValue();
        const deleteModal = findDeleteModal();
        deleteModal.vm.$emit('ok');
        testTrackingCall('confirm_delete');
      });
    });
  });
});
