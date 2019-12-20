import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import SidebarTodos from '~/sidebar/components/todo_toggle/todo.vue';
import Icon from '~/vue_shared/components/icon.vue';

const defaultProps = {
  issuableId: 1,
  issuableType: 'epic',
};

describe('SidebarTodo', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SidebarTodos, {
      sync: false,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    state    | classes
    ${false} | ${['btn', 'btn-default', 'btn-todo', 'issuable-header-btn', 'float-right']}
    ${true}  | ${['btn-blank', 'btn-todo', 'sidebar-collapsed-icon', 'dont-change-state']}
  `('returns todo button classes for when `collapsed` prop is `$state`', ({ state, classes }) => {
    createComponent({ collapsed: state });
    expect(wrapper.find('button').classes()).toStrictEqual(classes);
  });

  it.each`
    isTodo   | iconClass        | label             | icon
    ${false} | ${''}            | ${'Add a To Do'}  | ${'todo-add'}
    ${true}  | ${'todo-undone'} | ${'Mark as done'} | ${'todo-done'}
  `(
    'renders proper button when `isTodo` prop is `$isTodo`',
    ({ isTodo, iconClass, label, icon }) => {
      createComponent({ isTodo });

      expect(
        wrapper
          .find(Icon)
          .classes()
          .join(' '),
      ).toStrictEqual(iconClass);
      expect(wrapper.find(Icon).props('name')).toStrictEqual(icon);
      expect(wrapper.find('button').text()).toBe(label);
    },
  );

  describe('template', () => {
    it('emits `toggleTodo` event when clicked on button', () => {
      createComponent();
      wrapper.find('button').trigger('click');

      expect(wrapper.emitted().toggleTodo).toBeTruthy();
    });

    it('renders component container element with proper data attributes', () => {
      createComponent({
        issuableId: 1,
        issuableType: 'epic',
      });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders button label element when `collapsed` prop is `false`', () => {
      createComponent({ collapsed: false });

      expect(wrapper.find('span.issuable-todo-inner').text()).toBe('Mark as done');
    });

    it('renders button icon when `collapsed` prop is `true`', () => {
      createComponent({ collapsed: true });

      expect(wrapper.find(Icon).props('name')).toBe('todo-done');
    });

    it('renders loading icon when `isActionActive` prop is true', () => {
      createComponent({ isActionActive: true });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('hides button icon when `isActionActive` prop is true', () => {
      createComponent({ collapsed: true, isActionActive: true });

      expect(wrapper.find(Icon).isVisible()).toBe(false);
    });
  });
});
