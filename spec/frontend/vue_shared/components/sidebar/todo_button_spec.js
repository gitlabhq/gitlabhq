import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import TodoButton from '~/vue_shared/components/sidebar/todo_toggle/todo_button.vue';

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
    jest.spyOn(document, 'querySelector').mockReturnValue({
      innerText: 2,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    dispatchEventSpy = null;
    jest.clearAllMocks();
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

  it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
    createComponent({}, mount);
    wrapper.find(GlButton).trigger('click');
    const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];

    expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
    expect(dispatchedEvent.detail).toEqual({ count: 1 });
    expect(dispatchedEvent.type).toBe('todo:toggle');
  });

  it.each`
    label             | isTodo
    ${'Mark as done'} | ${true}
    ${'Add a to do'}  | ${false}
  `('sets correct label when isTodo is $isTodo', ({ label, isTodo }) => {
    createComponent({ isTodo });

    expect(wrapper.find(GlButton).text()).toBe(label);
  });

  it('binds additional props to GlButton', () => {
    createComponent({ loading: true });

    expect(wrapper.find(GlButton).props('loading')).toBe(true);
  });
});
