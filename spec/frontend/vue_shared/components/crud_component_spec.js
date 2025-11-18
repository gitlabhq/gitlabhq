import { nextTick } from 'vue';
import { GlButton, GlIcon, GlBadge, GlAnimatedChevronLgDownUpIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { parseBoolean } from '~/lib/utils/common_utils';

describe('CRUD Component', () => {
  useLocalStorageSpy();

  let wrapper;

  const createComponent = (propsData, slots = {}) => {
    wrapper = shallowMountExtended(CrudComponent, {
      propsData: {
        title: 'CRUD Component title',
        ...propsData,
      },
      scopedSlots: {
        ...slots,
      },
      stubs: { GlButton, GlIcon, GlBadge },
    });
  };

  const findTitle = () => wrapper.findByTestId('crud-title');
  const findDescription = () => wrapper.findByTestId('crud-description');
  const findCount = () => wrapper.findByTestId('crud-count');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findFormToggle = () => wrapper.findByTestId('crud-form-toggle');
  const findActions = () => wrapper.findByTestId('crud-actions');
  const findForm = () => wrapper.findByTestId('crud-form');
  const findSkeletonLoader = () => wrapper.findByTestId('crud-loading');
  const findEmpty = () => wrapper.findByTestId('crud-empty');
  const findBody = () => wrapper.findByTestId('crud-body');
  const findFooter = () => wrapper.findByTestId('crud-footer');
  const findPagination = () => wrapper.findByTestId('crud-pagination');
  const findCollapseToggle = () => wrapper.findByTestId('crud-collapse-toggle');
  const findChevronIcon = () => wrapper.findComponent(GlAnimatedChevronLgDownUpIcon);

  afterEach(() => {
    localStorage.clear();
  });

  it('renders title', () => {
    createComponent();

    expect(findTitle().text()).toBe('CRUD Component title');
  });

  it('renders the element specified by the containerTag prop', () => {
    createComponent({ containerTag: 'span' });
    expect(wrapper.element.tagName).toBe('SPAN');
  });

  it('renders `title` slot', () => {
    createComponent({}, { title: '<p>Title slot</p>' });

    expect(findTitle().text()).toBe('Title slot');
  });

  it('renders description', () => {
    createComponent({ description: 'Description' });

    expect(findDescription().text()).toBe('Description');
  });

  it('renders `description` slot', () => {
    createComponent({}, { description: '<p>Description slot</p>' });

    expect(findDescription().text()).toBe('Description slot');
  });

  it('renders count and icon appropriately when count does not exist', () => {
    createComponent({ icon: 'rocket' });

    expect(findCount().text()).toBe('0');
    expect(findIcon().props('name')).toBe('rocket');
  });

  it('renders count and icon appropriately when count exists', () => {
    createComponent({ count: 99, icon: 'rocket' });

    expect(findCount().text()).toBe('99');
    expect(findIcon().props('name')).toBe('rocket');
  });

  it('renders `count` slot', () => {
    createComponent({}, { count: '<p>Count slot</p>' });

    expect(findCount().text()).toBe('Count slot');
  });

  it('renders `actions` slot', () => {
    createComponent({}, { actions: '<p>Actions slot</p>' });

    expect(findActions().text()).toBe('Actions slot');
  });

  it('renders and shows `form` slot', async () => {
    createComponent({ toggleText: 'Form action toggle' }, { form: '<p>Form slot</p>' });

    expect(findForm().exists()).toBe(false);
    expect(findFormToggle().text()).toBe('Form action toggle');

    findFormToggle().vm.$emit('click');
    await nextTick();

    expect(findFormToggle().exists()).toBe(false);
    expect(findForm().text()).toBe('Form slot');
  });

  it("doesn't render content while loading", () => {
    createComponent({ isLoading: true }, { default: '<p>Body slot</p>' });

    expect(findSkeletonLoader().exists()).toBe(true);
    expect(findCount().exists()).toBe(false);
    expect(findIcon().exists()).toBe(false);
    expect(findBody().text()).toBe('');
  });

  it('renders `empty` slot', () => {
    createComponent({}, { empty: '<span>Empty message</span>' });

    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findEmpty().text()).toBe('Empty message');
  });

  it('renders `body` slot', () => {
    createComponent({}, { default: '<p>Body slot</p>' });

    expect(findSkeletonLoader().exists()).toBe(false);
    expect(findBody().text()).toBe('Body slot');
  });

  it('renders `footer` slot', () => {
    createComponent({}, { footer: '<p>Footer slot</p>' });

    expect(findFooter().text()).toBe('Footer slot');
  });

  it('renders `pagination` slot', () => {
    createComponent({}, { default: '<p>Body slot</p>', pagination: '<p>Pagination slot</p>' });

    expect(findPagination().text()).toBe('Pagination slot');
  });

  describe('with persistCollapsedState=true', () => {
    describe('when the localStorage key is undefined', () => {
      beforeEach(() => {
        createComponent(
          {
            isCollapsible: true,
            persistCollapsedState: true,
            anchorId: 'test-anchor',
            toggleText: 'Form action toggle',
          },
          { default: '<p>Body slot</p>' },
        );
      });

      it('the collapsible area is not collapsed initially', () => {
        expect(findBody().text()).toBe('Body slot');
      });

      it('toggles the collapsible area and sets the localStorage key to true', async () => {
        findCollapseToggle().vm.$emit('click');
        await nextTick();

        expect(localStorage.setItem).toHaveBeenCalledWith('crud-collapse-test-anchor', true);
        expect(findBody().exists()).toBe(false);
      });

      it('does not emit an event on mounted when no local storage key is set', () => {
        expect(wrapper.emitted('collapsed')).toBeUndefined();
        expect(wrapper.emitted('expanded')).toBeUndefined();
      });
    });

    describe('when the localStorage key is true', () => {
      beforeEach(() => {
        localStorage.setItem('crud-collapse-test-anchor', 'true');
        createComponent(
          {
            isCollapsible: true,
            persistCollapsedState: true,
            anchorId: 'test-anchor',
            toggleText: 'Form action toggle',
          },
          { default: '<p>Body slot</p>' },
        );
      });

      it('the collapsible area is collapsed initially', () => {
        expect(findBody().exists()).toBe(false);
      });

      it('emits an event on mounted', () => {
        expect(wrapper.emitted('collapsed').at(0)).toEqual([]);
        expect(wrapper.emitted('expanded')).toBeUndefined();
      });

      it('toggles the collapsible area and sets the localStorage key to false', async () => {
        findCollapseToggle().vm.$emit('click');
        await nextTick();

        expect(localStorage.setItem).toHaveBeenCalledWith('crud-collapse-test-anchor', false);
        expect(findBody().text()).toBe('Body slot');
      });
    });

    describe('when the localStorage key is false', () => {
      beforeEach(() => {
        localStorage.setItem('crud-collapse-test-anchor', 'false');
        createComponent(
          {
            isCollapsible: true,
            persistCollapsedState: true,
            anchorId: 'test-anchor',
            toggleText: 'Form action toggle',
          },
          { default: '<p>Body slot</p>' },
        );
      });

      it('emits an event on mounted', () => {
        expect(wrapper.emitted('collapsed')).toBeUndefined();
        expect(wrapper.emitted('expanded').at(0)).toEqual([]);
      });
    });
  });

  describe('isCollapsible', () => {
    it('renders collapsible toggle', () => {
      createComponent({ isCollapsible: true }, { default: '<p>Body slot</p>' });

      expect(findCollapseToggle().exists()).toBe(true);
      // Vue compat doesn't know about component props if it extends other component
      expect(
        findChevronIcon().props('isOn') ?? parseBoolean(findChevronIcon().attributes('is-on')),
      ).toBe(true);
    });

    it('click on toggle hides content', async () => {
      createComponent({ isCollapsible: true }, { default: '<p>Body slot</p>' });

      expect(findBody().exists()).toBe(true);

      await findCollapseToggle().vm.$emit('click');

      expect(findBody().exists()).toBe(false);
      // Vue compat doesn't know about component props if it extends other component
      expect(
        findChevronIcon().props('isOn') ?? parseBoolean(findChevronIcon().attributes('is-on')),
      ).toBe(false);
    });

    it('`collapsed` hides content by default', () => {
      createComponent({ isCollapsible: true, collapsed: true }, { default: '<p>Body slot</p>' });

      expect(findBody().exists()).toBe(false);
    });

    it('emits `expanded` when clicked on a collapsed toggle', async () => {
      createComponent({ isCollapsible: true, collapsed: true }, { default: '<p>Body slot</p>' });

      await findCollapseToggle().vm.$emit('click');

      expect(wrapper.emitted('expanded')).toStrictEqual([[]]);
    });

    it('emits `click-expanded` when clicked on a collapsed toggle, allowing for click tracking', async () => {
      createComponent({ isCollapsible: true, collapsed: true }, { default: '<p>Body slot</p>' });

      await findCollapseToggle().vm.$emit('click');

      expect(wrapper.emitted('click-expanded')).toStrictEqual([[]]);
    });

    it('emits `collapsed` when clicked on an expanded toggle', async () => {
      createComponent({ isCollapsible: true }, { default: '<p>Body slot</p>' });

      await findCollapseToggle().vm.$emit('click');

      expect(wrapper.emitted('collapsed')).toStrictEqual([[]]);
    });

    it('emits `click-collapsed` when clicked on an expanded toggle, allowing for click tracking', async () => {
      createComponent({ isCollapsible: true }, { default: '<p>Body slot</p>' });

      await findCollapseToggle().vm.$emit('click');

      expect(wrapper.emitted('click-collapsed')).toStrictEqual([[]]);
    });
  });

  describe('default slot', () => {
    it('passes the showForm function to the default slot', () => {
      const defaultSlot = jest.fn();
      createComponent({}, { default: defaultSlot });

      expect(defaultSlot).toHaveBeenCalledWith(
        expect.objectContaining({ showForm: wrapper.vm.showForm }),
      );
    });
  });

  describe('actions slot', () => {
    it('passes the showForm function to the actions slot', () => {
      const actionsSlot = jest.fn();
      createComponent({}, { actions: actionsSlot });

      expect(actionsSlot).toHaveBeenCalledWith(
        expect.objectContaining({ showForm: wrapper.vm.showForm }),
      );
    });
  });

  describe('showZeroCount prop', () => {
    it('displays "0" when count is falsy and showZeroCount is true', () => {
      createComponent({ showZeroCount: true, count: null });

      expect(findCount().text()).toBe('0');
    });

    it('does not display count when count is falsy and showZeroCount is false', () => {
      createComponent({ showZeroCount: false, count: null });

      expect(findCount().exists()).toBe(false);
    });

    it('displays "0" as string when count is 0 and showZeroCount is true', () => {
      createComponent({ showZeroCount: true, count: 0 });

      expect(findCount().text()).toBe('0');
    });

    it('displays regular count when count exists regardless of showZeroCount', () => {
      createComponent({ showZeroCount: true, count: 5 });

      expect(findCount().text()).toBe('5');
    });
  });
});
