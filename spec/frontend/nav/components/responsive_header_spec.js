import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ResponsiveHeader from '~/nav/components/responsive_header.vue';
import TopNavMenuItem from '~/nav/components/top_nav_menu_item.vue';

const TEST_SLOT_CONTENT = 'Test slot content';

describe('~/nav/components/top_nav_menu_sections.vue', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ResponsiveHeader, {
      slots: {
        default: TEST_SLOT_CONTENT,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findMenuItem = () => wrapper.findComponent(TopNavMenuItem);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders slot', () => {
    expect(wrapper.text()).toBe(TEST_SLOT_CONTENT);
  });

  it('renders back button', () => {
    const button = findMenuItem();

    const tooltip = getBinding(button.element, 'gl-tooltip').value.title;

    expect(tooltip).toBe('Go back');
    expect(button.props()).toEqual({
      menuItem: {
        id: 'home',
        view: 'home',
        icon: 'angle-left',
      },
      iconOnly: true,
    });
  });

  it('emits nothing', () => {
    expect(wrapper.emitted()).toEqual({});
  });

  describe('when back button is clicked', () => {
    beforeEach(() => {
      findMenuItem().vm.$emit('click');
    });

    it('emits menu-item-click', () => {
      expect(wrapper.emitted()).toEqual({
        'menu-item-click': [[{ id: 'home', view: 'home', icon: 'angle-left' }]],
      });
    });
  });
});
