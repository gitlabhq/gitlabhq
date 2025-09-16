import { GlButton, GlFormCheckbox, GlKeysetPagination, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';

describe('Registry List', () => {
  let wrapper;

  const items = [{ id: 'a' }, { id: 'b' }];
  const defaultPropsData = {
    items,
  };

  const rowScopedSlot = `
  <div data-testid="scoped-slot">
    <button @click="props.selectItem(props.item)">Select</button>
    <span>{{props.first}}</span>
    <p>{{props.isSelected(props.item)}}</p>
  </div>`;

  const mountComponent = ({ propsData = defaultPropsData } = {}) => {
    wrapper = shallowMountExtended(RegistryList, {
      propsData,
      scopedSlots: {
        default: rowScopedSlot,
      },
      stubs: {
        GlSprintf,
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
    describe('select all checkbox', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(findSelectAll().exists()).toBe(true);
        expect(findSelectAll().text()).toBe('Select all');
        expect(findSelectAll().props('disabled')).toBe(false);
        expect(findSelectAll().props('indeterminate')).toBe(false);
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
        await findSelectAll().vm.$emit('change', true);

        expect(findSelectAll().text()).toBe('Clear all');
      });

      it('select and unselect all', async () => {
        // no row is not selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('');
        });

        // simulate selection
        await findSelectAll().vm.$emit('change', true);

        // all rows selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('true');
        });

        // simulate de-selection
        await findSelectAll().vm.$emit('change', false);

        // no row is not selected
        items.forEach((item, index) => {
          expect(findScopedSlotIsSelectedValue(index).text()).toBe('false');
        });
      });
    });

    describe('delete button', () => {
      it('is hidden when no row is selected', () => {
        mountComponent();

        expect(findDeleteSelected().exists()).toBe(false);
      });

      it('is shown when `Select all` is selected', async () => {
        mountComponent();

        await findSelectAll().vm.$emit('change', true);

        expect(findDeleteSelected().text()).toBe('Delete selected');
      });

      it('is shown when row is selected', async () => {
        mountComponent();

        await findScopedSlotSelectButton(0).trigger('click');

        expect(findDeleteSelected().exists()).toBe(true);
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
