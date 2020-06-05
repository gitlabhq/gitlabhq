import { mount } from '@vue/test-utils';
import { GlTable, GlPagination, GlSkeletonLoader } from '@gitlab/ui';
import Tracking from '~/tracking';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/explorer/pages/details.vue';
import DeleteAlert from '~/registry/explorer/components/details_page/delete_alert.vue';
import DeleteModal from '~/registry/explorer/components/details_page/delete_modal.vue';
import DetailsHeader from '~/registry/explorer/components/details_page/details_header.vue';
import { createStore } from '~/registry/explorer/stores/';
import {
  SET_MAIN_LOADING,
  SET_TAGS_LIST_SUCCESS,
  SET_TAGS_PAGINATION,
  SET_INITIAL_STATE,
} from '~/registry/explorer/stores/mutation_types/';

import { tagsListResponse } from '../mock_data';
import { $toast } from '../../shared/mocks';

describe('Details Page', () => {
  let wrapper;
  let dispatchSpy;
  let store;

  const findDeleteModal = () => wrapper.find(DeleteModal);
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
  const findFirstTagNameText = () => wrapper.find('[data-testid="rowNameText"]');
  const findDeleteAlert = () => wrapper.find(DeleteAlert);
  const findDetailsHeader = () => wrapper.find(DetailsHeader);

  const routeId = window.btoa(JSON.stringify({ name: 'foo', tags_path: 'bar' }));

  const mountComponent = options => {
    wrapper = mount(component, {
      store,
      stubs: {
        ...stubChildren(component),
        GlSprintf: false,
        GlTable,
        DeleteModal,
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
    jest.spyOn(DeleteModal.methods, 'show');
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
    it.each([
      'rowCheckbox',
      'rowName',
      'rowShortRevision',
      'rowSize',
      'rowTime',
      'singleDeleteButton',
    ])('%s exist in the table', element => {
      mountComponent();
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
          expect(wrapper.vm.selectedItems).toEqual([store.state.tags[1].name]);
          expect(findFirstRowItem('rowCheckbox').attributes('checked')).toBeTruthy();
        });
      });

      it('if deselect remove name from selectedItems', () => {
        wrapper.setData({ selectedItems: [store.state.tags[1].name] });
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
        mountComponent();
        expect(findBulkDeleteButton().exists()).toBe(true);
      });

      it('is disabled if no item is selected', () => {
        mountComponent();
        expect(findBulkDeleteButton().attributes('disabled')).toBe('true');
      });

      it('is enabled if at least one item is selected', () => {
        mountComponent({ data: () => ({ selectedItems: [store.state.tags[0].name] }) });
        wrapper.setData({ selectedItems: [1] });
        return wrapper.vm.$nextTick().then(() => {
          expect(findBulkDeleteButton().attributes('disabled')).toBeFalsy();
        });
      });

      describe('on click', () => {
        it('when one item is selected', () => {
          mountComponent({ data: () => ({ selectedItems: [store.state.tags[0].name] }) });
          jest.spyOn(wrapper.vm.$refs.deleteModal, 'show');
          findBulkDeleteButton().vm.$emit('click');
          expect(wrapper.vm.itemsToBeDeleted).toEqual([store.state.tags[0]]);
          expect(DeleteModal.methods.show).toHaveBeenCalled();
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'registry_tag_delete',
          });
        });

        it('when multiple items are selected', () => {
          mountComponent({
            data: () => ({ selectedItems: store.state.tags.map(t => t.name) }),
          });
          findBulkDeleteButton().vm.$emit('click');

          expect(wrapper.vm.itemsToBeDeleted).toEqual(tagsListResponse.data);
          expect(DeleteModal.methods.show).toHaveBeenCalled();
          expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'bulk_registry_tag_delete',
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

        expect(DeleteModal.methods.show).toHaveBeenCalled();
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
          label: 'registry_tag_delete',
        });
      });
    });

    describe('name cell', () => {
      it('tag column has a tooltip with the tag name', () => {
        mountComponent();
        expect(findFirstTagNameText().attributes('title')).toBe(tagsListResponse.data[0].name);
      });

      describe('on desktop viewport', () => {
        beforeEach(() => {
          mountComponent();
        });

        it('table header has class w-25', () => {
          expect(findFirsTagColumn().classes()).toContain('w-25');
        });

        it('tag column has the mw-m class', () => {
          expect(findFirstRowItem('rowName').classes()).toContain('mw-m');
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

        it('table header does not have class w-25', () => {
          expect(findFirsTagColumn().classes()).not.toContain('w-25');
        });

        it('tag column has the gl-justify-content-end class', () => {
          expect(findFirstRowItem('rowName').classes()).toContain('gl-justify-content-end');
        });
      });
    });

    describe('last updated cell', () => {
      let timeCell;

      beforeEach(() => {
        mountComponent();
        timeCell = findFirstRowItem('rowTime');
      });

      it('displays the time in string format', () => {
        expect(timeCell.text()).toBe('2 years ago');
      });
      it('has a tooltip timestamp', () => {
        expect(timeCell.attributes('title')).toBe('Sep 19, 2017 1:45pm GMT+0000');
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
        const itemsToBeDeleted = [{ name: 'foo' }];

        it('dispatch requestDeleteTag with the right parameters', () => {
          mountComponent({ data: () => ({ itemsToBeDeleted }) });
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTag', {
            tag: itemsToBeDeleted[0],
            params: routeId,
          });
        });
        it('remove the deleted item from the selected items', () => {
          mountComponent({ data: () => ({ itemsToBeDeleted, selectedItems: ['foo', 'bar'] }) });
          findDeleteModal().vm.$emit('confirmDelete');
          expect(wrapper.vm.selectedItems).toEqual(['bar']);
        });
      });

      describe('when more than one item is selected to be deleted', () => {
        beforeEach(() => {
          mountComponent({
            data: () => ({
              itemsToBeDeleted: [{ name: 'foo' }, { name: 'bar' }],
              selectedItems: ['foo', 'bar'],
            }),
          });
        });

        it('dispatch requestDeleteTags with the right parameters', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(dispatchSpy).toHaveBeenCalledWith('requestDeleteTags', {
            ids: ['foo', 'bar'],
            params: routeId,
          });
        });
        it('clears the selectedItems', () => {
          findDeleteModal().vm.$emit('confirmDelete');
          expect(wrapper.vm.selectedItems).toEqual([]);
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
