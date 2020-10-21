import { shallowMount, mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TodoButton from '~/vue_shared/components/todo_button.vue';

describe('Todo Button', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TodoButton, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders GlButton', () => {
    createComponent();

    expect(wrapper.find(GlButton).exists()).toBe(true);
  });

  it('emits click event when clicked', () => {
    createComponent({}, mount);
    wrapper.find(GlButton).trigger('click');

    expect(wrapper.emitted().click).toBeTruthy();
  });

  it.each`
    label             | isTodo
    ${'Mark as done'} | ${true}
    ${'Add a To Do'}  | ${false}
  `('sets correct label when isTodo is $isTodo', ({ label, isTodo }) => {
    createComponent({ isTodo });

    expect(wrapper.find(GlButton).text()).toBe(label);
  });

  it('binds additional props to GlButton', () => {
    createComponent({ loading: true });

    expect(wrapper.find(GlButton).props('loading')).toBe(true);
  });
});
