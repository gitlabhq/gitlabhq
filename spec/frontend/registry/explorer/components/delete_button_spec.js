import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import component from '~/registry/explorer/components/delete_button.vue';

describe('delete_button', () => {
  let wrapper;

  const defaultProps = {
    title: 'Foo title',
    tooltipTitle: 'Bar tooltipTitle',
  };

  const findButton = () => wrapper.find(GlButton);

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('tooltip', () => {
    it('the title is controlled by tooltipTitle prop', () => {
      mountComponent();
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(defaultProps.tooltipTitle);
    });

    it('is disabled when tooltipTitle is disabled', () => {
      mountComponent({ tooltipDisabled: true });
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBe(true);
    });

    describe('button', () => {
      it('exists', () => {
        mountComponent();
        expect(findButton().exists()).toBe(true);
      });

      it('has the correct props/attributes bound', () => {
        mountComponent({ disabled: true });
        expect(findButton().attributes()).toMatchObject({
          'aria-label': 'Foo title',
          icon: 'remove',
          title: 'Foo title',
          variant: 'danger',
          disabled: 'true',
          category: 'secondary',
        });
      });

      it('emits a delete event', () => {
        mountComponent();
        expect(wrapper.emitted('delete')).toEqual(undefined);
        findButton().vm.$emit('click');
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });
  });
});
