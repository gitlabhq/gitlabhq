import { mount } from '@vue/test-utils';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

describe('DropdownButton component', () => {
  let wrapper;

  const defaultLabel = 'Select';
  const customLabel = 'Select project';

  const createComponent = (props, slots = {}) => {
    wrapper = mount(DropdownButton, { propsData: props, slots });
  };

  describe('computed', () => {
    describe('dropdownToggleText', () => {
      it('returns default toggle text', () => {
        createComponent();

        expect(wrapper.vm.toggleText).toBe(defaultLabel);
      });

      it('returns custom toggle text when provided via props', () => {
        createComponent({ toggleText: customLabel });

        expect(wrapper.vm.toggleText).toBe(customLabel);
      });
    });
  });

  describe('template', () => {
    it('renders component container element of type `button`', () => {
      createComponent();

      expect(wrapper.element.nodeName).toBe('BUTTON');
    });

    it('renders component container element with required data attributes', () => {
      createComponent();

      expect(wrapper.element.dataset.abilityName).toBe(wrapper.vm.abilityName);
      expect(wrapper.element.dataset.fieldName).toBe(wrapper.vm.fieldName);
      expect(wrapper.element.dataset.issueUpdate).toBe(wrapper.vm.updatePath);
      expect(wrapper.element.dataset.labels).toBe(wrapper.vm.labelsPath);
      expect(wrapper.element.dataset.namespacePath).toBe(wrapper.vm.namespace);
      expect(wrapper.element.dataset.showAny).toBeUndefined();
    });

    it('renders dropdown toggle text element', () => {
      createComponent();

      expect(wrapper.find('.dropdown-toggle-text').text()).toBe(defaultLabel);
    });

    it('renders dropdown button icon', () => {
      createComponent();

      expect(wrapper.find('[data-testid="chevron-down-icon"]').exists()).toBe(true);
    });

    it('renders slot, if default slot exists', () => {
      createComponent({}, { default: ['Lorem Ipsum Dolar'] });

      expect(wrapper.find('.dropdown-toggle-text').exists()).toBe(false);
      expect(wrapper.text()).toBe('Lorem Ipsum Dolar');
    });
  });
});
