import { mount, shallowMount } from '@vue/test-utils';
import DynamicPanel from '~/vue_shared/components/dynamic_panel.vue';
import PanelActions from '~/vue_shared/components/panel_actions.vue';

describe('DynamicPanel', () => {
  let wrapper;

  const findPanelActions = () => wrapper.findComponent(PanelActions);

  const createComponent = ({ mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(DynamicPanel, options);
  };

  it('renders the header prop text', () => {
    createComponent({ propsData: { header: 'My panel' } });
    expect(wrapper.text()).toContain('My panel');
  });

  it('renders the header slot content instead of the header prop', () => {
    createComponent({
      propsData: { header: 'Prop header' },
      slots: { header: 'Slot header' },
    });
    expect(wrapper.text()).toContain('Slot header');
    expect(wrapper.text()).not.toContain('Prop header');
  });

  it('renders default slot content', () => {
    createComponent({ slots: { default: 'Panel body' } });
    expect(wrapper.text()).toContain('Panel body');
  });

  it('emits close when the close button is clicked', async () => {
    createComponent();
    await findPanelActions().vm.$emit('close');
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('provides panelHeadingTag as h2 to descendants', () => {
    let injected;
    const Child = {
      inject: ['panelHeadingTag'],
      render() {
        injected = this.panelHeadingTag;
        return null;
      },
    };
    createComponent({ slots: { default: Child }, mountFn: mount });

    expect(injected).toBe('h2');
  });

  it('renders actions slot content', () => {
    const CustomAction = { template: '<button>Custom action</button>' };
    createComponent({ slots: { actions: CustomAction } });
    expect(wrapper.findComponent(CustomAction).exists()).toBe(true);
  });

  it('root element has the js-paneled-view class', () => {
    createComponent();
    expect(wrapper.classes()).toContain('js-paneled-view');
  });

  describe('maximizeUrl prop', () => {
    it('is null by default', () => {
      createComponent();
      expect(findPanelActions().props('maximizeUrl')).toBeNull();
    });

    it('is passed through to PanelActions', () => {
      createComponent({ propsData: { maximizeUrl: '/full/page' } });
      expect(findPanelActions().props('maximizeUrl')).toBe('/full/page');
    });
  });

  describe('maximize event', () => {
    it('is emitted when PanelActions emits maximize', async () => {
      createComponent({ propsData: { maximizeUrl: '/full/page' } });
      const mockEvent = new MouseEvent('click');
      await findPanelActions().vm.$emit('maximize', mockEvent);
      expect(wrapper.emitted('maximize')).toHaveLength(1);
      expect(wrapper.emitted('maximize')[0][0]).toBe(mockEvent);
    });
  });
});
