import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
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

  describe('shouldFillContent prop', () => {
    const fillClasses = ['gl-flex', 'gl-flex-col', 'gl-flex-1', 'gl-min-h-0'];
    const findContentInner = () => wrapper.findByTestId('panel-content-inner');
    const findContent = () => wrapper.findByTestId('panel-content');

    describe('when shouldFillContent is false', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not apply flex classes to the content wrapper chain', () => {
        fillClasses.forEach((cls) => {
          expect(findContentInner().classes()).not.toContain(cls);
          expect(findContainer().classes()).not.toContain(cls);
          expect(findContent().classes()).not.toContain(cls);
        });
      });
    });

    describe('when shouldFillContent is true', () => {
      beforeEach(() => {
        createComponent({ propsData: { shouldFillContent: true } });
      });

      it('applies flex classes to the content wrapper chain', () => {
        fillClasses.forEach((cls) => {
          expect(findContentInner().classes()).toContain(cls);
          expect(findContainer().classes()).toContain(cls);
          expect(findContent().classes()).toContain(cls);
        });
      });
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

  describe('panel content height', () => {
    const findScrollContainer = () => wrapper.findByTestId('panel-content-inner');

    it('sets --panel-content-inner-height on its own scroll container so nested panels do not collide', async () => {
      createComponent();
      const el = findScrollContainer().element;
      jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({ height: 742 });

      window.dispatchEvent(new Event('resize'));
      await nextTick();

      expect(el.style.getPropertyValue('--panel-content-inner-height')).toBe('742px');
    });

    it('stops updating the height after the component is destroyed', async () => {
      createComponent();
      const el = findScrollContainer().element;
      await nextTick();
      jest.spyOn(el, 'getBoundingClientRect').mockReturnValue({ height: 742 });
      wrapper.destroy();

      window.dispatchEvent(new Event('resize'));

      expect(el.style.getPropertyValue('--panel-content-inner-height')).not.toBe('742px');
    });
  });
});
