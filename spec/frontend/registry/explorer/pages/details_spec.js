import { mount } from '@vue/test-utils';
import { GlTable, GlPagination, GlSkeletonLoader, GlAlert, GlLink } from '@gitlab/ui';
import Tracking from '~/tracking';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/explorer/pages/details.vue';
import { createStore } from '~/registry/explorer/stores/';
import {
  SET_MAIN_LOADING,
  SET_INITIAL_STATE,
  SET_TAGS_LIST_SUCCESS,
  SET_TAGS_PAGINATION,
} from '~/registry/explorer/stores/mutation_types/';
import {
  DELETE_TAG_SUCCESS_MESSAGE,
  DELETE_TAG_ERROR_MESSAGE,
  DELETE_TAGS_SUCCESS_MESSAGE,
  DELETE_TAGS_ERROR_MESSAGE,
  ADMIN_GARBAGE_COLLECTION_TIP,
} from '~/registry/explorer/constants';
import { tagsListResponse } from '../mock_data';
import { GlModal } from '../stubs';
import { $toast } from '../../shared/mocks';

describe('Details Page', () => {
  let wrapper;
  let dispatchSpy;
  let store;

  const findDeleteModal = () => wrapper.find(GlModal);
  const findPagination = () => wrapper.find(GlPagination);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);
  const findMainCheckbox = () => wrapper.find({ ref: 'mainCheckbox' });
  const findFirstRowItem = ref => wrapper.find({ ref });
  const findBulkDeleteButton = () => wrapper.find({ ref: 'bulkDeleteButton' });
  // findAll and refs seems to no work falling back to class
  const findAllDeleteButtons = () => wrapper.findAll('.js-delete-registry');
  const findAllCheckboxes = () => wrapper.findAll('.js-row-checkbox');
  const findCheckedCheckboxes = () => findAllCheckboxes().filter(c => c.attributes('checked'));
  const findFirsTagColumn = () => wrapper.find('.js-tag-column');
  const findAlert = () => wrapper.find(GlAlert);

  const routeId = window.btoa(JSON.stringify({ name: 'foo', tags_path: 'bar' }));

  const mountComponent = options => {
    wrapper = mount(component, {
      store,
      stubs: {
        ...stubChildren(component),
        GlModal,
        GlSprintf: false,
        GlTable,
      },
      mocks: {
        $route: {
          params: {
            id: routeId,
          },
        },
        $toast,
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
      store.dispatch('receiveTagsListSuccess', { ...tagsListResponse, data: [] });
      store.commit(SET_MAIN_LOADING, true);
    });

    afterAll(() => store.commit(SET_MAIN_LOADING, false));

    it('has a skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not have list items', () => {
      expect(findFirstRowItem('rowCheckbox').exists()).toBe(false);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('table', () => {
    beforeEach(() => {
      mountComponent();
    });

    it.each([
      'rowCheckbox',
      'rowName',
      'rowShortRevision',
      'rowSize',
      'rowTime',
      'singleDeleteButton',
    ])('%s exist in the table', element => {
      expect(findFirstRowItem(element).exists()).toBe(true);
    });

    describe('header checkbox', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(findMainCheckbox().exists()).toBe(true);
      });

      it('if selected set selectedItem and allSelected', () => {
        findMainCheckbox().vm.$emit('change');
        return wrapper.vm.$nextTick().then(() => {
          expect(findMainCheckbox().attributes('checked')).toBeTruthy();
          expect(findCheckedCheckboxes()).toHaveLength(store.state.tags.length);
        });
      });

      it('if deselect unset selectedItem and allSelected', () => {
        wrapper.setData({ selectedItems: [1, 2], selectAllChecked: true });
        findMainCheckbox().vm.$emit('change');
        return wrapper.vm.$nextTick().then(() => {
          expect(findMainCheckbox().attributes('checked')).toBe(undefined);
          expect(findCheckedCheckboxes()).toHaveLength(0);
        });
      });
    });

    describe('row checkbox', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('if selected adds item to selectedItems', () => {
        findFirstRowItem('rowCheckbox').vm.$emit('change');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.selectedItems).toEqual([1]);
          expect(findFirstRowItem('rowCheckbox').attributes('checked')).toBeTruthy();
        });
      });

      it('if deselect remove index from selectedItems', () => {
        wrapper.setData({ selectedItems: [1] });
        findFirstRowItem('rowCheckbox').vm.$emit('change');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.selectedItems.length).toBe(0);
          expect(findFirstRowItem('rowCheckbox').attributes('checked')).toBe(undefined);
        });
      });
    });

    describe('header delete button', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(findBulkDeleteButton().exists()).toBe(true);
      });

      it('is disabled if no item is selected', () => {
        expect(findBulkDeleteButton().attributes('disabled')).toBe('true');
      });

      it('is enabled if at least one item is selected', () => {
        wrapper.setData({ selectedItems: [1] });
        return wrapper.vm.$nextTick().then(() => {
          expect(findBulkDeleteButton().attributes('disabled')).toBeFalsy();
        });
      });

      describe('on click', () => {
        it('when one item is selected', () => {
          wrapper.setData({ selectedItems: [1] });
          findBulkDeleteButton().vm.$emit('click');
          return wrapper.vm.$nextTick().then(() => {
            expect(findDeleteModal().html()).toContain(
              'You are about to remove <b>foo</b>. Are you sure?',
            );
            expect(GlModal.methods.show).toHaveBeenCalled();
            expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
              label: 'registry_tag_delete',
            });
          });
        });

        it('when multiple items are selected', () => {
          wrapper.setData({ selectedItems: [0, 1] });
          findBulkDeleteButton().vm.$emit('click');
          return wrapper.vm.$nextTick().then(() => {
            expect(findDeleteModal().html()).toContain(
              'You are about to remove <b>2</b> tags. Are you sure?',
            );
            expect(GlModal.methods.show).toHaveBeenCalled();
            expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
              label: 'bulk_registry_tag_delete',
            });
          });
        });
      });
    });

    describe('row delete button', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(
          findAllDeleteButtons()
            .at(0)
            .exists(),
        ).toBe(true);
      });

      it('is disabled if the item has no destroy_path', () => {
        expect(
          findAllDeleteButtons()
            .at(1)
            .attributes('disabled'),
        ).toBe('true');
      });

      it('on click', () => {
        findAllDeleteButtons()
          .at(0)
          .vm.$emit('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(findDeleteModal().html()).toContain(
            'You are about to remove <b>bar</b>. Are you sure?',
          );
          expect(GlModal.methods.show).toHaveBeenCalled();
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });
      });
    });

    describe('tag cell', () => {
      describe('on desktop viewport', () => {
        beforeEach(() => {
          mountComponent();
        });

        it('has class w-25', () => {
          expect(findFirsTagColumn().classes()).toContain('w-25');
        });
      });

      describe('on mobile viewport', () => {
        beforeEach(() => {
          mountComponent({
            data() {
              return { isDesktop: false };
            },
          });
        });

        it('does not has class w-25', () => {
          expect(findFirsTagColumn().classes()).not.toContain('w-25');
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
      wrapper.setData({ currentPage: 2 });
      expect(store.dispatch).toHaveBeenCalledWith('requestTagsList', {
        params: wrapper.vm.$route.params.id,
        pagination: { page: 2 },
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

    describe('when ok event is emitted', () => {
      beforeEach(() => {
        dispatchSpy.mockResolvedValue();
      });

      it('tracks confirm_delete', () => {
        const deleteModal = findDeleteModal();
        deleteModal.vm.$emit('ok');
        return wrapper.vm.$nextTick().then(() => {
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'confirm_delete', {
            label: 'registry_tag_delete',
          });
        });
      });

      describe('when only one element is selected', () => {
        it('execute the delete and remove selection', () => {
          wrapper.setData({ itemsToBeDeleted: [0] });
          findDeleteModal().vm.$emit('ok');

          expect(store.dispatch).toHaveBeenCalledWith('requestDeleteTag', {
            tag: store.state.tags[0],
            params: wrapper.vm.$route.params.id,
          });
          // itemsToBeDeleted is not represented in the DOM, is used as parking variable between selected and deleted items
          expect(wrapper.vm.itemsToBeDeleted).toEqual([]);
          expect(wrapper.vm.selectedItems).toEqual([]);
          expect(findCheckedCheckboxes()).toHaveLength(0);
        });
      });

      describe('when multiple elements are selected', () => {
        beforeEach(() => {
          wrapper.setData({ itemsToBeDeleted: [0, 1] });
        });

        it('execute the delete and remove selection', () => {
          findDeleteModal().vm.$emit('ok');

          expect(store.dispatch).toHaveBeenCalledWith('requestDeleteTags', {
            ids: store.state.tags.map(t => t.name),
            params: wrapper.vm.$route.params.id,
          });
          // itemsToBeDeleted is not represented in the DOM, is used as parking variable between selected and deleted items
          expect(wrapper.vm.itemsToBeDeleted).toEqual([]);
          expect(findCheckedCheckboxes()).toHaveLength(0);
        });
      });
    });

    it('tracks cancel_delete when cancel event is emitted', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('cancel');
      return wrapper.vm.$nextTick().then(() => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'cancel_delete', {
          label: 'registry_tag_delete',
        });
      });
    });
  });

  describe('Delete alert', () => {
    const config = {
      garbageCollectionHelpPagePath: 'foo',
    };

    describe('when the user is an admin', () => {
      beforeEach(() => {
        store.commit(SET_INITIAL_STATE, { ...config, isAdmin: true });
      });

      afterEach(() => {
        store.commit(SET_INITIAL_STATE, config);
      });

      describe.each`
        deleteType                | successTitle                   | errorTitle
        ${'handleSingleDelete'}   | ${DELETE_TAG_SUCCESS_MESSAGE}  | ${DELETE_TAG_ERROR_MESSAGE}
        ${'handleMultipleDelete'} | ${DELETE_TAGS_SUCCESS_MESSAGE} | ${DELETE_TAGS_ERROR_MESSAGE}
      `('behaves correctly on $deleteType', ({ deleteType, successTitle, errorTitle }) => {
        describe('when delete is successful', () => {
          beforeEach(() => {
            dispatchSpy.mockResolvedValue();
            mountComponent();
            return wrapper.vm[deleteType]('foo');
          });

          it('alert exists', () => {
            expect(findAlert().exists()).toBe(true);
          });

          it('alert body contains admin tip', () => {
            expect(
              findAlert()
                .text()
                .replace(/\s\s+/gm, ' '),
            ).toBe(ADMIN_GARBAGE_COLLECTION_TIP.replace(/%{\w+}/gm, ''));
          });

          it('alert body contains link', () => {
            const alertLink = findAlert().find(GlLink);
            expect(alertLink.exists()).toBe(true);
            expect(alertLink.attributes('href')).toBe(config.garbageCollectionHelpPagePath);
          });

          it('alert title is appropriate', () => {
            expect(findAlert().attributes('title')).toBe(successTitle);
          });
        });

        describe('when delete is not successful', () => {
          beforeEach(() => {
            mountComponent();
            dispatchSpy.mockRejectedValue();
            return wrapper.vm[deleteType]('foo');
          });

          it('alert exist and text is appropriate', () => {
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(errorTitle);
          });
        });
      });
    });

    describe.each`
      deleteType                | successTitle                   | errorTitle
      ${'handleSingleDelete'}   | ${DELETE_TAG_SUCCESS_MESSAGE}  | ${DELETE_TAG_ERROR_MESSAGE}
      ${'handleMultipleDelete'} | ${DELETE_TAGS_SUCCESS_MESSAGE} | ${DELETE_TAGS_ERROR_MESSAGE}
    `(
      'when the user is not an admin alert behaves correctly on $deleteType',
      ({ deleteType, successTitle, errorTitle }) => {
        beforeEach(() => {
          store.commit('SET_INITIAL_STATE', { ...config });
        });

        describe('when delete is successful', () => {
          beforeEach(() => {
            dispatchSpy.mockResolvedValue();
            mountComponent();
            return wrapper.vm[deleteType]('foo');
          });

          it('alert exist and text is appropriate', () => {
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(successTitle);
          });
        });

        describe('when delete is not successful', () => {
          beforeEach(() => {
            mountComponent();
            dispatchSpy.mockRejectedValue();
            return wrapper.vm[deleteType]('foo');
          });

          it('alert exist and text is appropriate', () => {
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(errorTitle);
          });
        });
      },
    );
  });
});
