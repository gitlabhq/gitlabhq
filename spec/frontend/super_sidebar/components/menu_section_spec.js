import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import FlyoutMenu from '~/super_sidebar/components/flyout_menu.vue';
import { stubComponent } from 'helpers/stub_component';

describe('MenuSection component', () => {
  let wrapper;

  const findButton = () => wrapper.find('button');
  const findCollapse = () => wrapper.getComponent(GlCollapse);
  const findFlyout = () => wrapper.findComponent(FlyoutMenu);
  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const createWrapper = (item, otherProps) => {
    wrapper = shallowMountExtended(MenuSection, {
      propsData: { item: { items: [], ...item }, ...otherProps },
      stubs: {
        GlCollapse: stubComponent(GlCollapse, {
          props: ['visible'],
        }),
      },
    });
  };

  it('renders its title', () => {
    createWrapper({ title: 'Asdf' });
    expect(findButton().text()).toBe('Asdf');
  });

  it('renders all its subitems', () => {
    createWrapper({
      title: 'Asdf',
      items: [
        { title: 'Item1', href: '/item1' },
        { title: 'Item2', href: '/item2' },
      ],
    });
    expect(findNavItems().length).toBe(2);
  });

  it('associates button with list with aria-controls', () => {
    createWrapper({ title: 'Asdf' });
    expect(findButton().attributes('aria-controls')).toBe('asdf');
    expect(findCollapse().attributes('id')).toBe('asdf');
  });

  describe('collapse behavior', () => {
    describe('when active', () => {
      it('is expanded', () => {
        createWrapper({ title: 'Asdf', is_active: true });
        expect(findCollapse().props('visible')).toBe(true);
      });
    });

    describe('when set to expanded', () => {
      it('is expanded', () => {
        createWrapper({ title: 'Asdf' }, { expanded: true });
        expect(findButton().attributes('aria-expanded')).toBe('true');
        expect(findCollapse().props('visible')).toBe(true);
      });
    });

    describe('when not active nor set to expanded', () => {
      it('is not expanded', () => {
        createWrapper({ title: 'Asdf' });
        expect(findButton().attributes('aria-expanded')).toBe('false');
        expect(findCollapse().props('visible')).toBe(false);
      });
    });
  });

  describe('flyout behavior', () => {
    describe('when hasFlyout is false', () => {
      it('is not rendered', () => {
        createWrapper({ title: 'Asdf' }, { 'has-flyout': false });
        expect(findFlyout().exists()).toBe(false);
      });
    });

    describe('when hasFlyout is true', () => {
      it('is not yet rendered', () => {
        createWrapper({ title: 'Asdf' }, { 'has-flyout': true });
        expect(findFlyout().exists()).toBe(false);
      });

      describe('on mouse hover', () => {
        describe('when section is expanded', () => {
          it('is not rendered', async () => {
            createWrapper({ title: 'Asdf' }, { 'has-flyout': true, expanded: true });
            await findButton().trigger('pointerover', { pointerType: 'mouse' });
            expect(findFlyout().exists()).toBe(false);
          });
        });

        describe('when section is not expanded', () => {
          describe('when section has no items', () => {
            it('is not rendered', async () => {
              createWrapper({ title: 'Asdf' }, { 'has-flyout': true, expanded: false });
              await findButton().trigger('pointerover', { pointerType: 'mouse' });
              expect(findFlyout().exists()).toBe(false);
            });
          });

          describe('when section has items', () => {
            beforeEach(() => {
              createWrapper(
                { title: 'Asdf', items: [{ title: 'Item1', href: '/item1' }] },
                { 'has-flyout': true, expanded: false },
              );
            });

            it('is rendered and shown', async () => {
              await findButton().trigger('pointerover', { pointerType: 'mouse' });
              expect(findFlyout().isVisible()).toBe(true);
            });

            it('adds a class to keep hover effect on button while flyout is hovered', async () => {
              await findButton().trigger('pointerover', { pointerType: 'mouse' });
              expect(findButton().classes()).not.toContain('with-mouse-over-flyout');
              await findFlyout().vm.$emit('mouseover');
              expect(findButton().classes()).toContain('with-mouse-over-flyout');
            });
          });
        });
      });

      describe('when section gets closed', () => {
        beforeEach(async () => {
          createWrapper(
            { title: 'Asdf', items: [{ title: 'Item1', href: '/item1' }] },
            { expanded: true, 'has-flyout': true },
          );
          await findButton().trigger('click');
          await findButton().trigger('pointerover', { pointerType: 'mouse' });
        });

        it('shows the flyout only after section title gets hovered out and in again', async () => {
          expect(findCollapse().props('visible')).toBe(false);
          expect(findFlyout().exists()).toBe(false);

          await findButton().trigger('pointerleave');
          await findButton().trigger('pointerover', { pointerType: 'mouse' });

          expect(findCollapse().props('visible')).toBe(false);
          expect(findFlyout().isVisible()).toBe(true);
        });
      });
    });
  });

  describe('`separated` prop', () => {
    describe('by default (false)', () => {
      it('does not render a separator', () => {
        createWrapper({ title: 'Asdf' });
        expect(wrapper.find('hr').exists()).toBe(false);
      });
    });

    describe('when set to true', () => {
      it('does render a separator', () => {
        createWrapper({ title: 'Asdf' }, { separated: true });
        expect(wrapper.find('hr').exists()).toBe(true);
      });
    });
  });

  describe('`tag` prop', () => {
    describe('by default', () => {
      it('renders as <div> tag', () => {
        createWrapper({ title: 'Asdf' });
        expect(wrapper.element.tagName).toBe('DIV');
      });
    });

    describe('when set to "li"', () => {
      it('renders as <li> tag', () => {
        createWrapper({ title: 'Asdf' }, { tag: 'li' });
        expect(wrapper.element.tagName).toBe('LI');
      });
    });
  });
});
