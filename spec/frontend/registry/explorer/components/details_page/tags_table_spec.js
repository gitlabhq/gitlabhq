import { mount } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/explorer/components/details_page/tags_table.vue';
import { tagsListResponse } from '../../mock_data';

describe('tags_table', () => {
  let wrapper;
  const tags = [...tagsListResponse.data];

  const findMainCheckbox = () => wrapper.find('[data-testid="mainCheckbox"]');
  const findFirstRowItem = testid => wrapper.find(`[data-testid="${testid}"]`);
  const findBulkDeleteButton = () => wrapper.find('[data-testid="bulkDeleteButton"]');
  const findAllDeleteButtons = () => wrapper.findAll('[data-testid="singleDeleteButton"]');
  const findAllCheckboxes = () => wrapper.findAll('[data-testid="rowCheckbox"]');
  const findCheckedCheckboxes = () => findAllCheckboxes().filter(c => c.attributes('checked'));
  const findFirsTagColumn = () => wrapper.find('.js-tag-column');
  const findFirstTagNameText = () => wrapper.find('[data-testid="rowNameText"]');

  const findLoaderSlot = () => wrapper.find('[data-testid="loaderSlot"]');
  const findEmptySlot = () => wrapper.find('[data-testid="emptySlot"]');

  const mountComponent = (propsData = { tags, isDesktop: true }) => {
    wrapper = mount(component, {
      stubs: {
        ...stubChildren(component),
        GlTable: false,
      },
      propsData,
      slots: {
        loader: '<div data-testid="loaderSlot"></div>',
        empty: '<div data-testid="emptySlot"></div>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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
    it('exists', () => {
      mountComponent();
      expect(findMainCheckbox().exists()).toBe(true);
    });

    it('if selected selects all the rows', () => {
      mountComponent();
      findMainCheckbox().vm.$emit('change');
      return wrapper.vm.$nextTick().then(() => {
        expect(findMainCheckbox().attributes('checked')).toBeTruthy();
        expect(findCheckedCheckboxes()).toHaveLength(tags.length);
      });
    });

    it('if deselect deselects all the row', () => {
      mountComponent();
      findMainCheckbox().vm.$emit('change');
      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(findMainCheckbox().attributes('checked')).toBeTruthy();
          findMainCheckbox().vm.$emit('change');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findMainCheckbox().attributes('checked')).toBe(undefined);
          expect(findCheckedCheckboxes()).toHaveLength(0);
        });
    });
  });

  describe('row checkbox', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('selecting and deselecting the checkbox works as intended', () => {
      findFirstRowItem('rowCheckbox').vm.$emit('change');
      return wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.selectedItems).toEqual([tags[0].name]);
          expect(findFirstRowItem('rowCheckbox').attributes('checked')).toBeTruthy();
          findFirstRowItem('rowCheckbox').vm.$emit('change');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
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
      expect(findBulkDeleteButton().attributes('disabled')).toBe('true');
      findFirstRowItem('rowCheckbox').vm.$emit('change');
      return wrapper.vm.$nextTick().then(() => {
        expect(findBulkDeleteButton().attributes('disabled')).toBeFalsy();
      });
    });

    describe('on click', () => {
      it('when one item is selected', () => {
        findFirstRowItem('rowCheckbox').vm.$emit('change');
        findBulkDeleteButton().vm.$emit('click');
        expect(wrapper.emitted('delete')).toEqual([[['centos6']]]);
      });

      it('when multiple items are selected', () => {
        findMainCheckbox().vm.$emit('change');
        findBulkDeleteButton().vm.$emit('click');

        expect(wrapper.emitted('delete')).toEqual([[tags.map(t => t.name)]]);
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

      expect(wrapper.emitted('delete')).toEqual([[['centos6']]]);
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
        mountComponent({ tags, isDesktop: false });
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

  describe('empty state slot', () => {
    describe('when the table is empty', () => {
      beforeEach(() => {
        mountComponent({ tags: [], isDesktop: true });
      });

      it('does not show table rows', () => {
        expect(findFirstTagNameText().exists()).toBe(false);
      });

      it('has the empty state slot', () => {
        expect(findEmptySlot().exists()).toBe(true);
      });
    });

    describe('when the table is not empty', () => {
      beforeEach(() => {
        mountComponent({ tags, isDesktop: true });
      });

      it('does show table rows', () => {
        expect(findFirstTagNameText().exists()).toBe(true);
      });

      it('does not show the empty state', () => {
        expect(findEmptySlot().exists()).toBe(false);
      });
    });
  });

  describe('loader slot', () => {
    describe('when the data is loading', () => {
      beforeEach(() => {
        mountComponent({ isLoading: true, tags });
      });

      it('show the loader', () => {
        expect(findLoaderSlot().exists()).toBe(true);
      });

      it('does not show the table rows', () => {
        expect(findFirstTagNameText().exists()).toBe(false);
      });
    });

    describe('when the data is not loading', () => {
      beforeEach(() => {
        mountComponent({ isLoading: false, tags });
      });

      it('does not show the loader', () => {
        expect(findLoaderSlot().exists()).toBe(false);
      });

      it('shows the table rows', () => {
        expect(findFirstTagNameText().exists()).toBe(true);
      });
    });
  });
});
