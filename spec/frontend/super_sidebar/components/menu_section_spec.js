import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { stubComponent } from 'helpers/stub_component';

describe('MenuSection component', () => {
  let wrapper;

  const findCollapse = () => wrapper.getComponent(GlCollapse);
  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const createWrapper = (item, otherProps) => {
    wrapper = shallowMountExtended(MenuSection, {
      propsData: { item, ...otherProps },
      stubs: {
        GlCollapse: stubComponent(GlCollapse, {
          props: ['visible'],
        }),
      },
    });
  };

  it('renders its title', () => {
    createWrapper({ title: 'Asdf' });
    expect(wrapper.find('button').text()).toBe('Asdf');
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
        expect(findCollapse().props('visible')).toBe(true);
      });
    });

    describe('when not active nor set to expanded', () => {
      it('is not expanded', () => {
        createWrapper({ title: 'Asdf' });
        expect(findCollapse().props('visible')).toBe(false);
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
      it('renders as <section> tag', () => {
        createWrapper({ title: 'Asdf' });
        expect(wrapper.element.tagName).toBe('SECTION');
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
