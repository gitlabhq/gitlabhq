import { mount } from '@vue/test-utils';
import { keepAlive } from './keep_alive_component_helper';

const component = {
  template: '<div>Test Component</div>',
};

describe('keepAlive', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(keepAlive(component));
  });

  it('converts a component to a keep-alive component', async () => {
    const { element } = wrapper.findComponent(component);

    await wrapper.vm.deactivate();
    expect(wrapper.findComponent(component).exists()).toBe(false);

    await wrapper.vm.activate();

    // assert that when the component is destroyed and re-rendered, the
    // newly rendered component has the reference to the old component
    // (i.e. the old component was deactivated and activated)
    expect(wrapper.findComponent(component).element).toBe(element);
  });
});
