import { GlButton, GlFormCheckbox, GlKeysetPagination } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import component from '~/packages_and_registries/shared/components/registry_list.vue';

describe('Registry List', () => {
  let wrapper;

  const items = [{ id: 'a' }, { id: 'b' }];
  const defaultPropsData = {
    title: 'test_title',
    items,
  };

  const rowScopedSlot = `
  <div data-testid="scoped-slot">
    <button @click="props.selectItem(props.item)">Select</button>
    <span>{{props.first}}</span>
    <p>{{props.isSelected(props.item)}}</p>
  </div>`;

  const mountComponent = ({ propsData = defaultPropsData } = {}) => {
    wrapper = shallowMountExtended(component, {
      propsData,
      scopedSlots: {
        default: rowScopedSlot,
      },
    });
  };

  const findSelectAll = () => wrapper.findComponent(GlFormCheckbox);
  const findDeleteSelected = () => wrapper.findComponent(GlButton);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findScopedSlots = () => wrapper.findAllByTestId('scoped-slot');
  const findScopedSlotSelectButton = (index) => findScopedSlots().at(index).find('button');
  const findScopedSlotFirstValue = (index) => findScopedSlots().at(index).find('span');
  const findScopedSlotIsSelectedValue = (index) => findScopedSlots().at(index).find('p');

  describe('header', () => {
    it('renders the title passed in the prop', () => {
      mountComponent();

      expect(wrapper.text()).toContain(defaultPropsData.title);
    });

    describe('select all checkbox', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(findSelectAll().exists()).toBe(true);
        expect(findSelectAll().attributes('aria-label')).toBe('Select all');
        expect(findSelectAll().attributes('disabled')).toBeUndefined();
        expect(findSelectAll().attributes('indeterminate')).toBeUndefined();
      });

      it('sets disabled prop to true when items length is 0', () => {
        mountComponent({ propsData: { ...defaultPropsData, items: [] } });

        expect(findSelectAll().attributes('disabled')).toBeDefined();
      });

      it('when few are selected, sets indeterminate prop to true', async () => {
        await findScopedSlotSelectButton(0).trigger('click');

        expect(findSelectAll().attributes('indeterminate')).toBe('true');
      });

      it('when all are selected, sets the right checkbox label', async () => {
        findSelectAll().vm.$emit('change', true);
        await nextTick();

        expect(findSelectAll().attributes('aria-label')).toBe('Unselect all');
      });

      it('select and unselect all', async () => {
        // no row is not selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('');
        });

        // simulate selection
        findSelectAll().vm.$emit('change', true);
        await nextTick();

        // all rows selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('true');
        });

        // simulate de-selection
        findSelectAll().vm.$emit('change', false);
        await nextTick();

        // no row is not selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('false');
        });
      });
    });

    describe('delete button', () => {
      it('has the correct text', () => {
        mountComponent();

        expect(findDeleteSelected().text()).toBe(component.i18n.deleteSelected);
      });

      describe('when hiddenDelete is true', () => {
        beforeEach(() => {
          mountComponent({ propsData: { ...defaultPropsData, hiddenDelete: true } });
        });

        it('is hidden', () => {
          expect(findDeleteSelected().exists()).toBe(false);
        });

        it('populates the first slot prop correctly', () => {
          expect(findScopedSlots().at(0).exists()).toBe(true);

          // it's the first slot
          expect(findScopedSlotFirstValue(0).text()).toBe('false');
        });
      });

      it('is disabled when isLoading is true', () => {
        mountComponent({ propsData: { ...defaultPropsData, isLoading: true } });

        expect(findDeleteSelected().props('disabled')).toBe(true);
      });

      it('is disabled when no row is selected', async () => {
        mountComponent();

        expect(findDeleteSelected().props('disabled')).toBe(true);

        await findScopedSlotSelectButton(0).trigger('click');

        expect(findDeleteSelected().props('disabled')).toBe(false);
      });

      it('on click emits the delete event with the selected rows', async () => {
        mountComponent();

        await findScopedSlotSelectButton(0).trigger('click');

        findDeleteSelected().vm.$emit('click');

        expect(wrapper.emitted('delete')).toEqual([[[items[0]]]]);
      });
    });
  });

  describe('main area', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders scopedSlots based on the items props', () => {
      expect(findScopedSlots()).toHaveLength(items.length);
    });

    it('populates the scope of the slot correctly', async () => {
      expect(findScopedSlots().at(0).exists()).toBe(true);

      // it's the first slot
      expect(findScopedSlotFirstValue(0).text()).toBe('true');

      // item is not selected, falsy is translated to empty string
      expect(findScopedSlotIsSelectedValue(0).text()).toBe('');

      // find the button with the bound function
      await findScopedSlotSelectButton(0).trigger('click');

      // the item is selected
      expect(findScopedSlotIsSelectedValue(0).text()).toBe('true');
    });
  });

  describe('footer', () => {
    let pagination;

    beforeEach(() => {
      pagination = { hasPreviousPage: false, hasNextPage: true };
    });

    it('has pagination', () => {
      mountComponent({
        propsData: { ...defaultPropsData, pagination },
      });

      expect(findPagination().props()).toMatchObject(pagination);
    });

    it('pagination emits the correct events', () => {
      mountComponent({
        propsData: { ...defaultPropsData, pagination },
      });

      findPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev-page')).toEqual([[]]);

      findPagination().vm.$emit('next');

      expect(wrapper.emitted('next-page')).toEqual([[]]);
    });
  });
});
