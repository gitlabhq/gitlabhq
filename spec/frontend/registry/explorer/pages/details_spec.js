import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import Tracking from '~/tracking';
import component from '~/registry/explorer/pages/details.vue';
import DeleteAlert from '~/registry/explorer/components/details_page/delete_alert.vue';
import PartialCleanupAlert from '~/registry/explorer/components/details_page/partial_cleanup_alert.vue';
import DetailsHeader from '~/registry/explorer/components/details_page/details_header.vue';
import TagsLoader from '~/registry/explorer/components/details_page/tags_loader.vue';
import TagsList from '~/registry/explorer/components/details_page/tags_list.vue';
import EmptyTagsState from '~/registry/explorer/components/details_page/empty_tags_state.vue';
import { createStore } from '~/registry/explorer/stores/';
import {
  SET_MAIN_LOADING,
  SET_TAGS_LIST_SUCCESS,
  SET_TAGS_PAGINATION,
  SET_INITIAL_STATE,
  SET_IMAGE_DETAILS,
} from '~/registry/explorer/stores/mutation_types';

import { tagsListResponse, imageDetailsMock } from '../mock_data';
import { DeleteModal } from '../stubs';

describe('Details Page', () => {
  let wrapper;
  let dispatchSpy;
  let store;

  const findDeleteModal = () => wrapper.find(DeleteModal);
  const findPagination = () => wrapper.find(GlPagination);
  const findTagsLoader = () => wrapper.find(TagsLoader);
  const findTagsList = () => wrapper.find(TagsList);
  const findDeleteAlert = () => wrapper.find(DeleteAlert);
  const findDetailsHeader = () => wrapper.find(DetailsHeader);
  const findEmptyTagsState = () => wrapper.find(EmptyTagsState);
  const findPartialCleanupAlert = () => wrapper.find(PartialCleanupAlert);

  const routeId = 1;

  const tagsArrayToSelectedTags = tags =>
    tags.reduce((acc, c) => {
      acc[c.name] = true;
      return acc;
    }, {});

  const mountComponent = ({ options } = {}) => {
    wrapper = shallowMount(component, {
      store,
      stubs: {
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
    store.commit(SET_IMAGE_DETAILS, imageDetailsMock);
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('lifecycle events', () => {
    it('calls the appropriate action on mount', () => {
      mountComponent();
      expect(dispatchSpy).toHaveBeenCalledWith('requestImageDetailsAndTagsList', routeId);
    });
  });

  describe('when isLoading is true', () => {
    beforeEach(() => {
      store.commit(SET_MAIN_LOADING, true);
      mountComponent();
    });

    afterEach(() => store.commit(SET_MAIN_LOADING, false));

    it('shows the loader', () => {
      expect(findTagsLoader().exists()).toBe(true);
    });

    it('does not show the list', () => {
      expect(findTagsList().exists()).toBe(false);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when the list of tags is empty', () => {
    beforeEach(() => {
      store.commit(SET_TAGS_LIST_SUCCESS, []);
      mountComponent();
    });

    it('has the empty state', () => {
      expect(findEmptyTagsState().exists()).toBe(true);
    });

    it('does not show the loader', () => {
      expect(findTagsLoader().exists()).toBe(false);
    });

    it('does not show the list', () => {
      expect(findTagsList().exists()).toBe(false);
    });
  });

  describe('list', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findTagsList().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      expect(findTagsList().props()).toMatchObject({
        isMobile: false,
        tags: store.state.tags,
      });
    });

    describe('deleteEvent', () => {
      describe('single item', () => {
        let tagToBeDeleted;
        beforeEach(() => {
          [tagToBeDeleted] = store.state.tags;
          findTagsList().vm.$emit('delete', { [tagToBeDeleted.name]: true });
        });

        it('open the modal', () => {
          expect(DeleteModal.methods.show).toHaveBeenCalled();
        });

        it('maps the selection to itemToBeDeleted', () => {
          expect(wrapper.vm.itemsToBeDeleted).toEqual([tagToBeDeleted]);
        });

        it('tracks a single delete event', () => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });
      });

      describe('multiple items', () => {
        beforeEach(() => {
          findTagsList().vm.$emit('delete', tagsArrayToSelectedTags(store.state.tags));
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
        page: 2,
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
          findTagsList().vm.$emit('delete', { [store.state.tags[0].name]: true });
        });

        it('dispatch requestDeleteTag with the right parameters', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTag', {
            tag: store.state.tags[0],
          });
        });
      });

      describe('when more than one item is selected to be deleted', () => {
        beforeEach(() => {
          mountComponent();
          findTagsList().vm.$emit('delete', tagsArrayToSelectedTags(store.state.tags));
        });

        it('dispatch requestDeleteTags with the right parameters', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTags', {
            ids: store.state.tags.map(t => t.name),
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
      expect(findDetailsHeader().props()).toEqual({ imageName: imageDetailsMock.name });
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
        options: {
          data: () => ({
            deleteAlertType,
          }),
        },
      });
      expect(findDeleteAlert().props()).toEqual({ ...config, deleteAlertType });
    });
  });

  describe('Partial Cleanup Alert', () => {
    const config = {
      runCleanupPoliciesHelpPagePath: 'foo',
      cleanupPoliciesHelpPagePath: 'bar',
    };

    describe('when expiration_policy_started is not null', () => {
      beforeEach(() => {
        store.commit(SET_IMAGE_DETAILS, {
          ...imageDetailsMock,
          cleanup_policy_started_at: Date.now().toString(),
        });
      });
      it('exists', () => {
        mountComponent();

        expect(findPartialCleanupAlert().exists()).toBe(true);
      });

      it('has the correct props', () => {
        store.commit(SET_INITIAL_STATE, { ...config });

        mountComponent();

        expect(findPartialCleanupAlert().props()).toEqual({ ...config });
      });

      it('dismiss hides the component', async () => {
        mountComponent();

        expect(findPartialCleanupAlert().exists()).toBe(true);
        findPartialCleanupAlert().vm.$emit('dismiss');

        await wrapper.vm.$nextTick();

        expect(findPartialCleanupAlert().exists()).toBe(false);
      });
    });

    describe('when expiration_policy_started is null', () => {
      it('the component is hidden', () => {
        mountComponent();

        expect(findPartialCleanupAlert().exists()).toBe(false);
      });
    });
  });
});
