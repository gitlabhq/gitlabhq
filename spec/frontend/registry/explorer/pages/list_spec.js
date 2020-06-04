import { shallowMount } from '@vue/test-utils';
import { GlSkeletonLoader, GlSprintf, GlAlert, GlSearchBoxByClick } from '@gitlab/ui';
import Tracking from '~/tracking';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/registry/explorer/pages/list.vue';
import CliCommands from '~/registry/explorer/components/list_page/cli_commands.vue';
import GroupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';
import ProjectEmptyState from '~/registry/explorer/components/list_page/project_empty_state.vue';
import RegistryHeader from '~/registry/explorer/components/list_page/registry_header.vue';
import ImageList from '~/registry/explorer/components/list_page/image_list.vue';
import { createStore } from '~/registry/explorer/stores/';
import {
  SET_MAIN_LOADING,
  SET_IMAGES_LIST_SUCCESS,
  SET_PAGINATION,
  SET_INITIAL_STATE,
} from '~/registry/explorer/stores/mutation_types/';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  IMAGE_REPOSITORY_LIST_LABEL,
  SEARCH_PLACEHOLDER_TEXT,
} from '~/registry/explorer/constants';
import { imagesListResponse } from '../mock_data';
import { GlModal, GlEmptyState } from '../stubs';
import { $toast } from '../../shared/mocks';

describe('List Page', () => {
  let wrapper;
  let dispatchSpy;
  let store;

  const findDeleteModal = () => wrapper.find(GlModal);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);

  const findEmptyState = () => wrapper.find(GlEmptyState);

  const findCliCommands = () => wrapper.find(CliCommands);
  const findProjectEmptyState = () => wrapper.find(ProjectEmptyState);
  const findGroupEmptyState = () => wrapper.find(GroupEmptyState);
  const findRegistryHeader = () => wrapper.find(RegistryHeader);

  const findDeleteAlert = () => wrapper.find(GlAlert);
  const findImageList = () => wrapper.find(ImageList);
  const findListHeader = () => wrapper.find('[data-testid="listHeader"]');
  const findSearchBox = () => wrapper.find(GlSearchBoxByClick);
  const findEmptySearchMessage = () => wrapper.find('[data-testid="emptySearch"]');

  const mountComponent = ({ mocks } = {}) => {
    wrapper = shallowMount(component, {
      store,
      stubs: {
        GlModal,
        GlEmptyState,
        GlSprintf,
        RegistryHeader,
      },
      mocks: {
        $toast,
        $route: {
          name: 'foo',
        },
        ...mocks,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    dispatchSpy = jest.spyOn(store, 'dispatch');
    dispatchSpy.mockResolvedValue();
    store.commit(SET_IMAGES_LIST_SUCCESS, imagesListResponse.data);
    store.commit(SET_PAGINATION, imagesListResponse.headers);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('API calls', () => {
    it.each`
      imageList                  | name         | called
      ${[]}                      | ${'foo'}     | ${['requestImagesList']}
      ${imagesListResponse.data} | ${undefined} | ${['requestImagesList']}
      ${imagesListResponse.data} | ${'foo'}     | ${undefined}
    `(
      'with images equal $imageList and name $name dispatch calls $called',
      ({ imageList, name, called }) => {
        store.commit(SET_IMAGES_LIST_SUCCESS, imageList);
        dispatchSpy.mockClear();
        mountComponent({ mocks: { $route: { name } } });

        expect(dispatchSpy.mock.calls[0]).toEqual(called);
      },
    );
  });

  it('contains registry header', () => {
    mountComponent();
    expect(findRegistryHeader().exists()).toBe(true);
  });

  describe('connection error', () => {
    const config = {
      characterError: true,
      containersErrorImage: 'foo',
      helpPagePath: 'bar',
    };

    beforeEach(() => {
      store.commit(SET_INITIAL_STATE, config);
      mountComponent();
    });

    afterEach(() => {
      store.commit(SET_INITIAL_STATE, {});
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
      expect(findImageList().exists()).toBe(false);
    });
  });

  describe('isLoading is true', () => {
    beforeEach(() => {
      store.commit(SET_MAIN_LOADING, true);
      mountComponent();
    });

    afterEach(() => store.commit(SET_MAIN_LOADING, false));

    it('shows the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      expect(findImageList().exists()).toBe(false);
    });

    it('cli commands is not visible', () => {
      expect(findCliCommands().exists()).toBe(false);
    });
  });

  describe('list is empty', () => {
    beforeEach(() => {
      store.commit(SET_IMAGES_LIST_SUCCESS, []);
      mountComponent();
      return waitForPromises();
    });

    it('cli commands is not visible', () => {
      expect(findCliCommands().exists()).toBe(false);
    });

    it('project empty state is visible', () => {
      expect(findProjectEmptyState().exists()).toBe(true);
    });

    describe('is group page is true', () => {
      beforeEach(() => {
        store.commit(SET_INITIAL_STATE, { isGroupPage: true });
        mountComponent();
      });

      afterEach(() => {
        store.commit(SET_INITIAL_STATE, { isGroupPage: undefined });
      });

      it('group empty state is visible', () => {
        expect(findGroupEmptyState().exists()).toBe(true);
      });

      it('cli commands is not visible', () => {
        expect(findCliCommands().exists()).toBe(false);
      });

      it('list header is not visible', () => {
        expect(findListHeader().exists()).toBe(false);
      });
    });
  });

  describe('list is not empty', () => {
    describe('unfiltered state', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('quick start is visible', () => {
        expect(findCliCommands().exists()).toBe(true);
      });

      it('list component is visible', () => {
        expect(findImageList().exists()).toBe(true);
      });

      it('list header is  visible', () => {
        const header = findListHeader();
        expect(header.exists()).toBe(true);
        expect(header.text()).toBe(IMAGE_REPOSITORY_LIST_LABEL);
      });

      describe('delete image', () => {
        const itemToDelete = { path: 'bar' };
        it('should call deleteItem when confirming deletion', () => {
          dispatchSpy.mockResolvedValue();
          findImageList().vm.$emit('delete', itemToDelete);
          expect(wrapper.vm.itemToDelete).toEqual(itemToDelete);
          findDeleteModal().vm.$emit('ok');
          expect(store.dispatch).toHaveBeenCalledWith(
            'requestDeleteImage',
            wrapper.vm.itemToDelete,
          );
        });

        it('should show a success alert when delete request is successful', () => {
          dispatchSpy.mockResolvedValue();
          findImageList().vm.$emit('delete', itemToDelete);
          expect(wrapper.vm.itemToDelete).toEqual(itemToDelete);
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
          findImageList().vm.$emit('delete', itemToDelete);
          expect(wrapper.vm.itemToDelete).toEqual(itemToDelete);
          return wrapper.vm.handleDeleteImage().then(() => {
            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_ERROR_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });
        });
      });
    });

    describe('search', () => {
      it('has a search box element', () => {
        mountComponent();
        const searchBox = findSearchBox();
        expect(searchBox.exists()).toBe(true);
        expect(searchBox.attributes('placeholder')).toBe(SEARCH_PLACEHOLDER_TEXT);
      });

      it('performs a search', () => {
        mountComponent();
        findSearchBox().vm.$emit('submit', 'foo');
        expect(store.dispatch).toHaveBeenCalledWith('requestImagesList', {
          name: 'foo',
        });
      });

      it('when search result is empty displays an empty search message', () => {
        mountComponent();
        store.commit(SET_IMAGES_LIST_SUCCESS, []);
        return wrapper.vm.$nextTick().then(() => {
          expect(findEmptySearchMessage().exists()).toBe(true);
        });
      });
    });

    describe('pagination', () => {
      it('pageChange event triggers the appropriate store function', () => {
        mountComponent();
        findImageList().vm.$emit('pageChange', 2);
        expect(store.dispatch).toHaveBeenCalledWith('requestImagesList', {
          pagination: { page: 2 },
          name: wrapper.vm.search,
        });
      });
    });
  });

  describe('modal', () => {
    beforeEach(() => {
      mountComponent();
    });

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
    beforeEach(() => {
      mountComponent();
    });

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
      findImageList().vm.$emit('delete', {});
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
