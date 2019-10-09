import Vue from 'vue';
import tableRegistry from '~/registry/components/table_registry.vue';
import { mount } from '@vue/test-utils';
import { repoPropsData } from '../mock_data';

const [firstImage, secondImage] = repoPropsData.list;

describe('table registry', () => {
  let wrapper;

  const findSelectAllCheckbox = w => w.find('.js-select-all-checkbox > input');
  const findSelectCheckboxes = w => w.findAll('.js-select-checkbox > input');
  const findDeleteButton = w => w.find('.js-delete-registry');
  const findDeleteButtonsRow = w => w.findAll('.js-delete-registry-row');
  const findPagination = w => w.find('.js-registry-pagination');
  const bulkDeletePath = 'path';

  beforeEach(() => {
    // This is needed due to  console.error called by vue to emit a warning that stop the tests
    // see  https://github.com/vuejs/vue-test-utils/issues/532
    Vue.config.silent = true;
    wrapper = mount(tableRegistry, {
      propsData: {
        repo: repoPropsData,
      },
    });
  });

  afterEach(() => {
    Vue.config.silent = false;
  });

  describe('rendering', () => {
    it('should render a table with the registry list', () => {
      expect(wrapper.findAll('.registry-image-row').length).toEqual(repoPropsData.list.length);
    });

    it('should render registry tag', () => {
      const tds = wrapper.findAll('.registry-image-row td');
      expect(tds.at(0).classes()).toContain('check');
      expect(tds.at(1).html()).toContain(repoPropsData.list[0].tag);
      expect(tds.at(2).html()).toContain(repoPropsData.list[0].shortRevision);
      expect(tds.at(3).html()).toContain(repoPropsData.list[0].layers);
      expect(tds.at(3).html()).toContain(repoPropsData.list[0].size);
      expect(tds.at(4).html()).toContain(wrapper.vm.timeFormated(repoPropsData.list[0].createdAt));
    });
  });

  describe('multi select', () => {
    it('selecting a row should enable delete button', done => {
      const deleteBtn = findDeleteButton(wrapper);
      const checkboxes = findSelectCheckboxes(wrapper);

      expect(deleteBtn.attributes('disabled')).toBe('disabled');

      checkboxes.at(0).trigger('click');
      Vue.nextTick(() => {
        expect(deleteBtn.attributes('disabled')).toEqual(undefined);
        done();
      });
    });

    it('selecting all checkbox should select all rows and enable delete button', done => {
      const selectAll = findSelectAllCheckbox(wrapper);
      const checkboxes = findSelectCheckboxes(wrapper);
      selectAll.trigger('click');

      Vue.nextTick(() => {
        const checked = checkboxes.filter(w => w.element.checked);
        expect(checked.length).toBe(checkboxes.length);
        done();
      });
    });

    it('deselecting select all checkbox should deselect all rows and disable delete button', done => {
      const checkboxes = findSelectCheckboxes(wrapper);
      const selectAll = findSelectAllCheckbox(wrapper);
      selectAll.trigger('click');
      selectAll.trigger('click');

      Vue.nextTick(() => {
        const checked = checkboxes.filter(w => !w.element.checked);
        expect(checked.length).toBe(checkboxes.length);
        done();
      });
    });

    it('should delete multiple items when multiple items are selected', done => {
      const multiDeleteItems = jest.fn().mockResolvedValue();
      wrapper.setMethods({ multiDeleteItems });
      const selectAll = findSelectAllCheckbox(wrapper);
      selectAll.trigger('click');

      Vue.nextTick(() => {
        const deleteBtn = findDeleteButton(wrapper);
        expect(wrapper.vm.itemsToBeDeleted).toEqual([0, 1]);
        expect(deleteBtn.attributes('disabled')).toEqual(undefined);
        wrapper.vm.handleMultipleDelete();

        Vue.nextTick(() => {
          expect(wrapper.vm.itemsToBeDeleted).toEqual([]);
          expect(wrapper.vm.multiDeleteItems).toHaveBeenCalledWith({
            path: bulkDeletePath,
            items: [firstImage.tag, secondImage.tag],
          });
          done();
        });
      });
    });

    it('should show an error message if bulkDeletePath is not set', () => {
      const showError = jest.fn();
      wrapper.setMethods({ showError });
      wrapper.setProps({
        repo: {
          ...repoPropsData,
          tagsPath: null,
        },
      });
      wrapper.vm.handleMultipleDelete();
      expect(wrapper.vm.showError).toHaveBeenCalled();
    });
  });

  describe('delete registry', () => {
    beforeEach(() => {
      wrapper.setData({ itemsToBeDeleted: [0] });
    });

    it('should be possible to delete a registry', () => {
      const deleteBtn = findDeleteButton(wrapper);
      const deleteBtns = findDeleteButtonsRow(wrapper);
      expect(wrapper.vm.itemsToBeDeleted).toEqual([0]);
      expect(deleteBtn).toBeDefined();
      expect(deleteBtn.attributes('disable')).toBe(undefined);
      expect(deleteBtns.is('button')).toBe(true);
    });

    it('should allow deletion row by row', () => {
      const deleteBtns = findDeleteButtonsRow(wrapper);
      const deleteSingleItem = jest.fn();
      const deleteItem = jest.fn().mockResolvedValue();
      wrapper.setMethods({ deleteSingleItem, deleteItem });
      deleteBtns.at(0).trigger('click');
      expect(wrapper.vm.deleteSingleItem).toHaveBeenCalledWith(0);
      wrapper.vm.handleSingleDelete(1);
      expect(wrapper.vm.deleteItem).toHaveBeenCalledWith(1);
    });
  });

  describe('pagination', () => {
    let localWrapper = null;
    const repo = {
      repoPropsData,
      pagination: {
        total: 20,
        perPage: 2,
        nextPage: 2,
      },
    };

    beforeEach(() => {
      localWrapper = mount(tableRegistry, {
        propsData: {
          repo,
        },
      });
    });

    it('should exist', () => {
      const pagination = findPagination(localWrapper);
      expect(pagination.exists()).toBe(true);
    });
    it('should be visible when pagination is needed', () => {
      const pagination = findPagination(localWrapper);
      expect(pagination.isVisible()).toBe(true);
      localWrapper.setProps({
        repo: {
          pagination: {
            total: 0,
            perPage: 10,
          },
        },
      });
      expect(localWrapper.vm.shouldRenderPagination).toBe(false);
    });
    it('should have a change function that update the list when run', () => {
      const fetchList = jest.fn().mockResolvedValue();
      localWrapper.setMethods({ fetchList });
      localWrapper.vm.onPageChange(1);
      expect(localWrapper.vm.fetchList).toHaveBeenCalledWith({ repo, page: 1 });
    });
  });

  describe('modal content', () => {
    it('should show the singular title and image name when deleting a single image', () => {
      wrapper.setData({ itemsToBeDeleted: [1] });
      wrapper.vm.setModalDescription(0);
      expect(wrapper.vm.modalAction).toBe('Remove tag');
      expect(wrapper.vm.modalDescription).toContain(firstImage.tag);
    });

    it('should show the plural title and image count when deleting more than one image', () => {
      wrapper.setData({ itemsToBeDeleted: [1, 2] });
      wrapper.vm.setModalDescription();

      expect(wrapper.vm.modalAction).toBe('Remove tags');
      expect(wrapper.vm.modalDescription).toContain('<b>2</b> tags');
    });
  });
});
