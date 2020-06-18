import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import Tracking from '~/tracking';
import component from '~/registry/explorer/pages/details.vue';
import DeleteAlert from '~/registry/explorer/components/details_page/delete_alert.vue';
import DetailsHeader from '~/registry/explorer/components/details_page/details_header.vue';
import TagsLoader from '~/registry/explorer/components/details_page/tags_loader.vue';
import EmptyTagsState from '~/registry/explorer/components/details_page/empty_tags_state.vue';
import { createStore } from '~/registry/explorer/stores/';
import {
  SET_MAIN_LOADING,
  SET_TAGS_LIST_SUCCESS,
  SET_TAGS_PAGINATION,
  SET_INITIAL_STATE,
} from '~/registry/explorer/stores/mutation_types/';

import { tagsListResponse } from '../mock_data';
import { TagsTable, DeleteModal } from '../stubs';

describe('Details Page', () => {
  let wrapper;
  let dispatchSpy;
  let store;

  const findDeleteModal = () => wrapper.find(DeleteModal);
  const findPagination = () => wrapper.find(GlPagination);
  const findTagsLoader = () => wrapper.find(TagsLoader);
  const findTagsTable = () => wrapper.find(TagsTable);
  const findDeleteAlert = () => wrapper.find(DeleteAlert);
  const findDetailsHeader = () => wrapper.find(DetailsHeader);
  const findEmptyTagsState = () => wrapper.find(EmptyTagsState);

  const routeId = window.btoa(JSON.stringify({ name: 'foo', tags_path: 'bar' }));

  const mountComponent = options => {
    wrapper = shallowMount(component, {
      store,
      stubs: {
        TagsTable,
        DeleteModal,
      },
      mocks: {
        $route: {
          params: {
            id: routeId,
          },
        },
      },
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    dispatchSpy = jest.spyOn(store, 'dispatch');
    dispatchSpy.mockResolvedValue();
    store.commit(SET_TAGS_LIST_SUCCESS, tagsListResponse.data);
    store.commit(SET_TAGS_PAGINATION, tagsListResponse.headers);
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when isLoading is true', () => {
    beforeEach(() => {
      mountComponent();
      store.commit(SET_MAIN_LOADING, true);
      return wrapper.vm.$nextTick();
    });

    afterEach(() => store.commit(SET_MAIN_LOADING, false));

    it('binds isLoading to tags-table', () => {
      expect(findTagsTable().props('isLoading')).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('table slots', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('has the empty state', () => {
      expect(findEmptyTagsState().exists()).toBe(true);
    });

    it('has a skeleton loader', () => {
      expect(findTagsLoader().exists()).toBe(true);
    });
  });

  describe('table', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findTagsTable().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findTagsTable().props()).toMatchObject({
        isDesktop: true,
        isLoading: false,
        tags: store.state.tags,
      });
    });

    describe('deleteEvent', () => {
      describe('single item', () => {
        beforeEach(() => {
          findTagsTable().vm.$emit('delete', [store.state.tags[0].name]);
        });

        it('open the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('maps the selection to itemToBeDeleted', () => {
          expect(wrapper.vm.itemsToBeDeleted).toEqual([store.state.tags[0]]);
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });
      });

      describe('multiple items', () => {
        beforeEach(() => {
          findTagsTable().vm.$emit('delete', store.state.tags.map(t => t.name));
        });

        it('open the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('maps the selection to itemToBeDeleted', () => {
          expect(wrapper.vm.itemsToBeDeleted).toEqual(store.state.tags);
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'bulk_registry_tag_delete',
          });
        });
      });
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('is wired to the correct pagination props', () => {
      const pagination = findPagination();
      expect(pagination.props('perPage')).toBe(store.state.tagsPagination.perPage);
      expect(pagination.props('totalItems')).toBe(store.state.tagsPagination.total);
      expect(pagination.props('value')).toBe(store.state.tagsPagination.page);
    });

    it('fetch the data from the API when the v-model changes', () => {
      dispatchSpy.mockResolvedValue();
      findPagination().vm.$emit(GlPagination.model.event, 2);
      expect(store.dispatch).toHaveBeenCalledWith('requestTagsList', {
        params: wrapper.vm.$route.params.id,
        pagination: { page: 2 },
      });
    });
  });

  describe('modal', () => {
    it('exists', () => {
      mountComponent();
      expect(findDeleteModal().exists()).toBe(true);
    });

    describe('cancel event', () => {
      it('tracks cancel_delete', () => {
        mountComponent();
        findDeleteModal().vm.$emit('cancel');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'cancel_delete', {
          label: 'registry_tag_delete',
        });
      });
    });

    describe('confirmDelete event', () => {
      describe('when one item is selected to be deleted', () => {
        beforeEach(() => {
          mountComponent();
          findTagsTable().vm.$emit('delete', [store.state.tags[0].name]);
        });

        it('dispatch requestDeleteTag with the right parameters', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTag', {
            tag: store.state.tags[0],
            params: routeId,
          });
        });
      });

      describe('when more than one item is selected to be deleted', () => {
        beforeEach(() => {
          mountComponent();
          findTagsTable().vm.$emit('delete', store.state.tags.map(t => t.name));
        });

        it('dispatch requestDeleteTags with the right parameters', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTags', {
            ids: store.state.tags.map(t => t.name),
            params: routeId,
          });
        });
      });
    });
  });

  describe('Header', () => {
    it('exists', () => {
      mountComponent();
      expect(findDetailsHeader().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();
      expect(findDetailsHeader().props()).toEqual({ imageName: 'foo' });
    });
  });

  describe('Delete Alert', () => {
    const config = {
      isAdmin: true,
      garbageCollectionHelpPagePath: 'baz',
    };
    const deleteAlertType = 'success_tag';

    it('exists', () => {
      mountComponent();
      expect(findDeleteAlert().exists()).toBe(true);
    });

    it('has the correct props', () => {
      store.commit(SET_INITIAL_STATE, { ...config });
      mountComponent({
        data: () => ({
          deleteAlertType,
        }),
      });
      expect(findDeleteAlert().props()).toEqual({ ...config, deleteAlertType });
    });
  });
});
