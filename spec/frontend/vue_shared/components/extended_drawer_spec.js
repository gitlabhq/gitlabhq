import { nextTick } from 'vue';
import { GlButton, GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import ExtendedDrawer from '~/vue_shared/components/extended_drawer.vue';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

describe('ExtendedDrawer', () => {
  let wrapper;

  const GlDrawerStub = stubComponent(GlDrawer, {
    template: `
      <div>
        <slot name="title"></slot>
        <slot name="header"></slot>
        <slot></slot>
        <slot name="footer"></slot>
      </div>
    `,
  });

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findTitle = () => wrapper.find('h2');
  const findExpandButton = () => wrapper.findComponentByTestId('extended-drawer-expand-button');
  const findPrimary = () => wrapper.findByTestId('extended-drawer-primary');
  const findPrimaryScroll = () => wrapper.findByTestId('extended-drawer-primary-scroll');
  const findSecondary = () => wrapper.findByTestId('extended-drawer-secondary');
  const findSplitWrapper = () => wrapper.findByTestId('extended-drawer-split');

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(ExtendedDrawer, {
      propsData: {
        open: true,
        title: 'Sessions',
        ...props,
      },
      slots: {
        default: '<p data-testid="primary-content">Primary content</p>',
        ...slots,
      },
      stubs: {
        GlDrawer: GlDrawerStub,
      },
    });
  };

  describe('GlDrawer integration', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes open, headerHeight, headerSticky and the default zIndex through to GlDrawer', () => {
      expect(findDrawer().props()).toMatchObject({
        open: true,
        headerHeight: '',
        headerSticky: false,
        zIndex: DRAWER_Z_INDEX,
      });
    });

    it('passes a custom zIndex and headerHeight through to GlDrawer', () => {
      createComponent({ props: { zIndex: 700, headerHeight: '48px' } });

      expect(findDrawer().props()).toMatchObject({
        zIndex: 700,
        headerHeight: '48px',
      });
    });

    it('re-emits the close event from GlDrawer', () => {
      findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('registers the drawer as the width container the split layout responds to', () => {
      expect(findDrawer().classes()).toContain('gl-@container');
    });

    it('focuses the drawer and re-emits opened when GlDrawer finishes opening', () => {
      const focusSpy = jest.spyOn(findDrawer().element, 'focus');

      findDrawer().vm.$emit('opened');

      expect(focusSpy).toHaveBeenCalled();
      expect(wrapper.emitted('opened')).toHaveLength(1);
    });
  });

  describe('title', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title as a heading', () => {
      expect(findTitle().text()).toBe('Sessions');
    });

    it('labels the drawer with the heading', () => {
      expect(findDrawer().attributes('aria-labelledby')).toBe(findTitle().attributes('id'));
    });
  });

  describe('expand toggle', () => {
    it('renders the expand affordance when not expanded', () => {
      createComponent();

      expect(findExpandButton().props('icon')).toBe('collapse-left');
      expect(findExpandButton().attributes('aria-label')).toBe('Expand to full width');
    });

    it('emits expand when activated while not expanded', () => {
      createComponent();

      findExpandButton().vm.$emit('click');

      expect(wrapper.emitted('expand')).toHaveLength(1);
      expect(wrapper.emitted('collapse')).toBeUndefined();
    });

    it('renders the collapse affordance when expanded', () => {
      createComponent({ props: { expanded: true } });

      expect(findExpandButton().props('icon')).toBe('collapse-right');
      expect(findExpandButton().attributes('aria-label')).toBe('Collapse to drawer');
    });

    it('emits collapse when activated while expanded', () => {
      createComponent({ props: { expanded: true } });

      findExpandButton().vm.$emit('click');

      expect(wrapper.emitted('collapse')).toHaveLength(1);
      expect(wrapper.emitted('expand')).toBeUndefined();
    });
  });

  describe('expanded state', () => {
    it('does not apply the full width class by default', () => {
      createComponent();

      expect(findDrawer().classes()).not.toContain('!gl-w-full');
    });

    it('applies the full width class when expanded', () => {
      createComponent({ props: { expanded: true } });

      expect(findDrawer().classes()).toContain('!gl-w-full');
    });
  });

  describe('managed state', () => {
    it('expands and collapses locally when the toggle is activated', async () => {
      createComponent();

      findExpandButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('expand')).toHaveLength(1);
      expect(findDrawer().classes()).toContain('!gl-w-full');

      findExpandButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('collapse')).toHaveLength(1);
      expect(findDrawer().classes()).not.toContain('!gl-w-full');
    });

    it('follows later changes to the expanded prop', async () => {
      createComponent();

      await wrapper.setProps({ expanded: true });

      expect(findDrawer().classes()).toContain('!gl-w-full');
      expect(findExpandButton().attributes('aria-label')).toBe('Collapse to drawer');
    });

    it('closes itself when GlDrawer closes and reports it through close and update:open', async () => {
      createComponent();

      findDrawer().vm.$emit('close');
      await nextTick();

      expect(wrapper.emitted('close')).toHaveLength(1);
      expect(wrapper.emitted('update:open')).toEqual([[false]]);
      expect(findDrawer().props('open')).toBe(false);

      // A consumer following update:open (e.g. via .sync) has flipped its
      // prop to false, so setting it true again is a change that reopens.
      await wrapper.setProps({ open: false });
      await wrapper.setProps({ open: true });

      expect(findDrawer().props('open')).toBe(true);
    });
  });

  describe('secondary content area', () => {
    const secondarySlot = { secondary: '<p data-testid="secondary-content">Secondary content</p>' };

    describe('when not expanded and the secondary slot is provided', () => {
      beforeEach(() => {
        createComponent({ slots: secondarySlot });
      });

      it('does not render the secondary area', () => {
        expect(findSecondary().exists()).toBe(false);
      });

      it('keeps the primary content at full width (no grid split)', () => {
        expect(findSplitWrapper().classes()).not.toContain('@md:gl-grid');
      });

      it('leaves scrolling to the drawer body (no inner scroll containers)', () => {
        expect(findPrimary().classes()).not.toContain('@md:gl-overflow-hidden');
        expect(wrapper.findByTestId('extended-drawer-primary-scroll').classes()).not.toContain(
          '@md:gl-overflow-y-auto',
        );
      });

      it('does not make the primary area a focusable region', () => {
        expect(findPrimaryScroll().attributes('tabindex')).toBeUndefined();
        expect(findPrimaryScroll().attributes('role')).toBeUndefined();
      });
    });

    describe('when expanded and the secondary slot is provided', () => {
      beforeEach(() => {
        createComponent({ props: { expanded: true }, slots: secondarySlot });
      });

      it('renders both content areas', () => {
        expect(findPrimary().find('[data-testid="primary-content"]').exists()).toBe(true);
        expect(findSecondary().find('[data-testid="secondary-content"]').exists()).toBe(true);
      });

      it('splits the content areas into columns', () => {
        expect(findSplitWrapper().classes()).toContain('@md:gl-grid');
        expect(findSecondary().classes()).toContain('@md:gl-col-span-2');
      });

      it('stacks with a bottom divider below md and splits with a right divider above', () => {
        expect(findPrimary().classes()).toContain('gl-border-b');
        expect(findPrimary().classes()).toContain('@md:gl-border-b-0');
        expect(findPrimary().classes()).toContain('@md:gl-border-r');
      });

      it('gives each area its own scroll container', () => {
        expect(findPrimary().classes()).toContain('@md:gl-overflow-hidden');
        expect(wrapper.findByTestId('extended-drawer-primary-scroll').classes()).toContain(
          '@md:gl-overflow-y-auto',
        );
        expect(findSecondary().classes()).toContain('@md:gl-overflow-y-auto');
      });

      it('constrains the drawer body so the columns scroll instead of the drawer', () => {
        expect(findDrawer().props('headerSticky')).toBe(true);
      });

      it('makes each scroll region keyboard-focusable with its own accessible name', () => {
        expect(findPrimaryScroll().attributes()).toMatchObject({
          tabindex: '0',
          role: 'region',
          'aria-label': 'Primary content',
        });
        expect(findSecondary().attributes()).toMatchObject({
          tabindex: '0',
          role: 'region',
          'aria-label': 'Details',
        });
      });

      it('names the regions from the primaryLabel and secondaryLabel props', () => {
        createComponent({
          props: {
            expanded: true,
            primaryLabel: 'Sessions feed',
            secondaryLabel: 'Session details',
          },
          slots: secondarySlot,
        });

        expect(findPrimaryScroll().attributes('aria-label')).toBe('Sessions feed');
        expect(findSecondary().attributes('aria-label')).toBe('Session details');
      });
    });

    describe('when expanded with the slot provided but secondaryVisible false', () => {
      beforeEach(() => {
        createComponent({
          props: { expanded: true, secondaryVisible: false },
          slots: secondarySlot,
        });
      });

      it('does not render the secondary area and keeps full width', () => {
        expect(findSecondary().exists()).toBe(false);
        expect(findSplitWrapper().classes()).not.toContain('@md:gl-grid');
      });

      it('renders the secondary area once secondaryVisible flips to true', async () => {
        await wrapper.setProps({ secondaryVisible: true });

        expect(findSecondary().find('[data-testid="secondary-content"]').exists()).toBe(true);
        expect(findSplitWrapper().classes()).toContain('@md:gl-grid');
      });
    });

    describe('when expanded and the secondary slot is absent', () => {
      beforeEach(() => {
        createComponent({ props: { expanded: true } });
      });

      it('does not render the secondary area', () => {
        expect(findSecondary().exists()).toBe(false);
      });

      it('keeps the primary content at full width (no grid split)', () => {
        expect(findPrimary().find('[data-testid="primary-content"]').exists()).toBe(true);
        expect(findSplitWrapper().classes()).not.toContain('@md:gl-grid');
      });
    });
  });

  describe('focus management', () => {
    let trigger;

    // Real elements attached to the document so document.activeElement works.
    const createAttachedComponent = ({ props = {}, slots = {} } = {}) => {
      trigger = document.createElement('button');
      document.body.appendChild(trigger);
      trigger.focus();

      wrapper = shallowMountExtended(ExtendedDrawer, {
        propsData: { open: true, title: 'Sessions', ...props },
        slots: { default: '<p>Primary</p>', ...slots },
        stubs: {
          GlDrawer: GlDrawerStub,
          GlButton: stubComponent(GlButton, { template: '<button><slot></slot></button>' }),
        },
        attachTo: document.body,
      });
    };

    afterEach(() => {
      trigger?.remove();
      trigger = null;
    });

    it('moves focus into a drawer that mounts already open', async () => {
      createAttachedComponent();
      await nextTick();

      expect(document.activeElement).toBe(findDrawer().element);
    });

    it('restores focus to the previously focused element when a drawer that mounted open closes', async () => {
      createAttachedComponent();
      await nextTick();

      findDrawer().vm.$emit('close');
      await nextTick();

      expect(document.activeElement).toBe(trigger);
    });

    it('restores focus to the previously focused element on close', async () => {
      createAttachedComponent({ props: { open: false } });
      await wrapper.setProps({ open: true });
      findDrawer().vm.$emit('opened');

      findDrawer().vm.$emit('close');
      await nextTick();

      expect(document.activeElement).toBe(trigger);
    });

    it('leaves focus alone when it already moved outside the drawer', async () => {
      createAttachedComponent({ props: { open: false } });
      await wrapper.setProps({ open: true });
      findDrawer().vm.$emit('opened');

      const outside = document.createElement('input');
      document.body.appendChild(outside);
      outside.focus();

      findDrawer().vm.$emit('close');
      await nextTick();

      expect(document.activeElement).toBe(outside);
      outside.remove();
    });

    it('moves focus to the toggle when the secondary region unmounts while focused', async () => {
      createAttachedComponent({
        props: { expanded: true },
        slots: { secondary: '<p>Secondary</p>' },
      });
      // Let the mounted-open focus land before moving focus into the region.
      await nextTick();

      findSecondary().element.focus();
      await wrapper.setProps({ secondaryVisible: false });
      await nextTick();

      expect(document.activeElement).toBe(findExpandButton().element);
    });
  });

  describe('pass-through slots', () => {
    it('renders header slot content when provided', () => {
      createComponent({ slots: { header: '<p data-testid="header-content">Header</p>' } });

      expect(wrapper.findByTestId('header-content').exists()).toBe(true);
    });

    it('renders footer slot content when provided', () => {
      createComponent({ slots: { footer: '<p data-testid="footer-content">Footer</p>' } });

      expect(wrapper.findByTestId('footer-content').exists()).toBe(true);
    });
  });
});
