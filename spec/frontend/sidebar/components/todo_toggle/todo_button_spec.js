import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import TodoButton from '~/sidebar/components/todo_toggle/todo_button.vue';

describe('Todo Button', () => {
  let wrapper;
  let dispatchEventSpy;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TodoButton, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');
  });

  afterEach(() => {
    dispatchEventSpy = null;
  });

  it('renders GlButton', () => {
    createComponent();

    expect(wrapper.findComponent(GlButton).exists()).toBe(true);
  });

  it('emits click event when clicked', () => {
    createComponent({}, mount);
    wrapper.findComponent(GlButton).trigger('click');

    expect(wrapper.emitted().click).toHaveLength(1);
  });

  it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
    createComponent({}, mount);
    wrapper.findComponent(GlButton).trigger('click');
    const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];

    expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
    expect(dispatchedEvent.detail).toEqual({ delta: -1 });
    expect(dispatchedEvent.type).toBe('todo:toggle');
  });

  it.each`
    label                 | isTodo
    ${'Mark as done'}     | ${true}
    ${'Add a to-do item'} | ${false}
  `('sets correct label when isTodo is $isTodo', ({ label, isTodo }) => {
    createComponent({ isTodo });

    expect(wrapper.findComponent(GlButton).text()).toBe(label);
  });

  it('binds additional props to GlButton', () => {
    createComponent({ loading: true });

    expect(wrapper.findComponent(GlButton).props('loading')).toBe(true);
  });
});
