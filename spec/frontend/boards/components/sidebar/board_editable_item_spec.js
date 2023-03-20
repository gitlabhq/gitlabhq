import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import BoardSidebarItem from '~/boards/components/sidebar/board_editable_item.vue';

describe('boards sidebar remove issue', () => {
  let wrapper;

  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findEditButton = () => wrapper.find('[data-testid="edit-button"]');
  const findTitle = () => wrapper.find('[data-testid="title"]');
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');
  const findExpanded = () => wrapper.find('[data-testid="expanded-content"]');

  const createComponent = ({ props = {}, slots = {}, canUpdate = false } = {}) => {
    wrapper = shallowMount(BoardSidebarItem, {
      attachTo: document.body,
      provide: { canUpdate },
      propsData: props,
      slots,
    });
  };

  describe('template', () => {
    it('renders title', () => {
      const title = 'Sidebar item title';
      createComponent({ props: { title } });

      expect(findTitle().text()).toBe(title);
    });

    it('renders provided title slot', () => {
      const title = 'Sidebar item title on slot';
      const slots = { title: `<strong>${title}</strong>` };
      createComponent({ slots });

      expect(wrapper.text()).toContain(title);
    });

    it('hides edit button, loader and expanded content by default', () => {
      createComponent();

      expect(findEditButton().exists()).toBe(false);
      expect(findLoader().exists()).toBe(false);
      expect(findExpanded().isVisible()).toBe(false);
    });

    it('shows "None" if empty collapsed slot', () => {
      createComponent({});

      expect(findCollapsed().text()).toBe('None');
    });

    it('renders collapsed content by default', () => {
      const slots = { collapsed: '<div>Collapsed content</div>' };
      createComponent({ slots });

      expect(findCollapsed().text()).toBe('Collapsed content');
    });

    it('shows edit button if can update', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('shows loading icon if loading', () => {
      createComponent({ props: { loading: true } });

      expect(findLoader().exists()).toBe(true);
    });

    it('shows expanded content and hides collapsed content when clicking edit button', async () => {
      const slots = { default: '<div>Select item</div>' };
      createComponent({ canUpdate: true, slots });
      findEditButton().vm.$emit('click');

      await nextTick();
      expect(findCollapsed().isVisible()).toBe(false);
      expect(findExpanded().isVisible()).toBe(true);
    });

    it('hides the header while editing if `toggleHeader` is true', async () => {
      createComponent({ canUpdate: true, props: { toggleHeader: true } });
      findEditButton().vm.$emit('click');

      await nextTick();

      expect(findEditButton().isVisible()).toBe(false);
      expect(findTitle().isVisible()).toBe(false);
      expect(findExpanded().isVisible()).toBe(true);
    });
  });

  describe('collapsing an item by offclicking', () => {
    beforeEach(async () => {
      createComponent({ canUpdate: true });
      findEditButton().vm.$emit('click');
      await nextTick();
    });

    it('hides expanded section and displays collapsed section', async () => {
      expect(findExpanded().isVisible()).toBe(true);
      document.body.click();

      await nextTick();

      expect(findCollapsed().isVisible()).toBe(true);
      expect(findExpanded().isVisible()).toBe(false);
    });

    it('emits events', async () => {
      document.body.click();

      await nextTick();

      expect(wrapper.emitted().close).toHaveLength(1);
      expect(wrapper.emitted()['off-click']).toHaveLength(1);
    });
  });

  it('emits open when edit button is clicked and edit is initailized to false', async () => {
    createComponent({ canUpdate: true });

    findEditButton().vm.$emit('click');

    await nextTick();

    expect(wrapper.emitted().open.length).toBe(1);
  });

  it('does not emits events when collapsing with false `emitEvent`', async () => {
    createComponent({ canUpdate: true });

    findEditButton().vm.$emit('click');

    await nextTick();

    wrapper.vm.collapse({ emitEvent: false });

    expect(wrapper.emitted().close).toBeUndefined();
  });
});
