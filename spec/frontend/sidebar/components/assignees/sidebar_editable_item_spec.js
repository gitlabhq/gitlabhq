import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';

describe('boards sidebar remove issue', () => {
  let wrapper;

  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findEditButton = () => wrapper.find('[data-testid="edit-button"]');
  const findTitle = () => wrapper.find('[data-testid="title"]');
  const findCollapsed = () => wrapper.find('[data-testid="collapsed-content"]');
  const findExpanded = () => wrapper.find('[data-testid="expanded-content"]');

  const createComponent = ({ props = {}, slots = {}, canUpdate = false } = {}) => {
    wrapper = shallowMount(SidebarEditableItem, {
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

    it('hides edit button, loader and expanded content by default', () => {
      createComponent();

      expect(findEditButton().exists()).toBe(false);
      expect(findLoader().exists()).toBe(false);
      expect(findExpanded().isVisible()).toBe(false);
    });

    it('shows "None" if empty collapsed slot', () => {
      createComponent();

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

    describe('when clicking edit button', () => {
      describe('when can edit', () => {
        it('shows expanded (editable) content', async () => {
          const slots = { default: '<div>Select item</div>' };
          createComponent({ canUpdate: true, slots });
          findEditButton().vm.$emit('click');

          await nextTick();

          expect(findCollapsed().isVisible()).toBe(false);
          expect(findExpanded().isVisible()).toBe(true);
        });
      });

      describe('when cannot edit', () => {
        it('shows collapsed (non-editable) content', async () => {
          const slots = { default: '<div>Select item</div>' };
          createComponent({ canUpdate: false, slots });
          // Simulate parent component calling `expand` method when user
          // clicks on collapsed sidebar (e.g. in sidebar_weight_widget.vue)
          wrapper.vm.expand();
          await nextTick();

          expect(findCollapsed().isVisible()).toBe(true);
          expect(findExpanded().isVisible()).toBe(false);
        });
      });
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

  it('renders `Edit` test when passed `isDirty` prop is false', () => {
    createComponent({ props: { isDirty: false }, canUpdate: true });

    expect(findEditButton().text()).toBe('Edit');
  });

  it('renders `Apply` test when passed `isDirty` prop is true', () => {
    createComponent({ props: { isDirty: true }, canUpdate: true });

    expect(findEditButton().text()).toBe('Apply');
  });

  describe('when initial loading is true', () => {
    beforeEach(() => {
      createComponent({ props: { initialLoading: true } });
    });

    it('renders loading icon', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('does not render edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('does not render collapsed and expanded content', () => {
      expect(findCollapsed().exists()).toBe(false);
      expect(findExpanded().exists()).toBe(false);
    });
  });
});
