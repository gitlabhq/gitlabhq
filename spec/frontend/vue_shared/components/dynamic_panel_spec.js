import { mount } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DynamicPanel from '~/vue_shared/components/dynamic_panel.vue';
import PanelActions from '~/vue_shared/components/panel_actions.vue';

describe('DynamicPanel', () => {
  let wrapper;

  const findPanelActions = () => wrapper.findComponent(PanelActions);
  const findContainer = () => wrapper.findByTestId('layout-container');
  const findFooter = () => wrapper.findByTestId('panel-footer');

  const createComponent = ({ mountFn = shallowMountExtended, ...options } = {}) => {
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

  describe('footer slot', () => {
    it('does not render the footer when no footer slot is provided', () => {
      createComponent();
      expect(findFooter().exists()).toBe(false);
    });

    it('renders the footer when footer slot content is provided', () => {
      createComponent({ slots: { footer: 'Panel footer' } });
      expect(findFooter().text()).toContain('Panel footer');
    });
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

  describe('fluidLayout prop', () => {
    it('applies container-limited when gon.fluid_layout is not set', () => {
      createComponent();
      expect(findContainer().classes()).toContain('container-limited');
    });

    it('does not apply container-limited when gon.fluid_layout is true', () => {
      window.gon = { fluid_layout: true };
      createComponent();
      expect(findContainer().classes()).not.toContain('container-limited');
    });

    it('applies container-limited when gon.fluid_layout is false', () => {
      window.gon = { fluid_layout: false };
      createComponent();
      expect(findContainer().classes()).toContain('container-limited');
    });

    it('does not apply container-limited when fluidLayout prop is true', () => {
      createComponent({ propsData: { fluidLayout: true } });
      expect(findContainer().classes()).not.toContain('container-limited');
    });

    it('prop overrides gon.fluid_layout when explicitly set to false', () => {
      window.gon = { fluid_layout: true };
      createComponent({ propsData: { fluidLayout: false } });
      expect(findContainer().classes()).toContain('container-limited');
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
