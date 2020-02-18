import { mount } from '@vue/test-utils';
import { GlTable, GlPagination, GlLoadingIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/explorer/pages/details.vue';
import store from '~/registry/explorer/stores/';
import { SET_MAIN_LOADING } from '~/registry/explorer/stores/mutation_types/';
import { tagsListResponse } from '../mock_data';
import { GlModal } from '../stubs';

describe('Details Page', () => {
  let wrapper;
  let dispatchSpy;

  const findDeleteModal = () => wrapper.find(GlModal);
  const findPagination = () => wrapper.find(GlPagination);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findTagsTable = () => wrapper.find(GlTable);
  const findMainCheckbox = () => wrapper.find({ ref: 'mainCheckbox' });
  const findFirstRowItem = ref => wrapper.find({ ref });
  const findBulkDeleteButton = () => wrapper.find({ ref: 'bulkDeleteButton' });
  // findAll and refs seems to no work falling back to class
  const findAllDeleteButtons = () => wrapper.findAll('.js-delete-registry');
  const findAllCheckboxes = () => wrapper.findAll('.js-row-checkbox');
  const findCheckedCheckboxes = () => findAllCheckboxes().filter(c => c.attributes('checked'));

  const routeId = window.btoa(JSON.stringify({ name: 'foo', tags_path: 'bar' }));

  beforeEach(() => {
    wrapper = mount(component, {
      store,
      stubs: {
        ...stubChildren(component),
        GlModal,
        GlSprintf: false,
        GlTable: false,
      },
      mocks: {
        $route: {
          params: {
            id: routeId,
          },
        },
      },
    });
    dispatchSpy = jest.spyOn(store, 'dispatch');
    store.dispatch('receiveTagsListSuccess', tagsListResponse);
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when isLoading is true', () => {
    beforeAll(() => store.commit(SET_MAIN_LOADING, true));

    afterAll(() => store.commit(SET_MAIN_LOADING, false));

    it('has a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not have a main content', () => {
      expect(findTagsTable().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
      expect(findDeleteModal().exists()).toBe(false);
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
      expect(findFirstRowItem(element).exists()).toBe(true);
    });

    describe('header checkbox', () => {
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
  });

  describe('pagination', () => {
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
        id: wrapper.vm.$route.params.id,
        pagination: { page: 2 },
      });
    });
  });

  describe('modal', () => {
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

      it('when only one element is selected', () => {
        const deleteModal = findDeleteModal();

        wrapper.setData({ itemsToBeDeleted: [0] });
        deleteModal.vm.$emit('ok');

        return wrapper.vm.$nextTick().then(() => {
          expect(store.dispatch).toHaveBeenCalledWith('requestDeleteTag', {
            tag: store.state.tags[0],
            params: wrapper.vm.$route.params.id,
          });
          // itemsToBeDeleted is not represented in the DOM, is used as parking variable between selected and deleted items
          expect(wrapper.vm.itemsToBeDeleted).toEqual([]);
          expect(findCheckedCheckboxes()).toHaveLength(0);
        });
      });

      it('when multiple elements are selected', () => {
        const deleteModal = findDeleteModal();

        wrapper.setData({ itemsToBeDeleted: [0, 1] });
        deleteModal.vm.$emit('ok');

        return wrapper.vm.$nextTick().then(() => {
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
});
