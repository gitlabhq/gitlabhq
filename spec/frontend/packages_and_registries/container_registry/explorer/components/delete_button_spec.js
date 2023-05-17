import { GlButton, GlTooltip, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/container_registry/explorer/components/delete_button.vue';
import { LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION } from '~/packages_and_registries/container_registry/explorer/constants/list';

describe('delete_button', () => {
  let wrapper;

  const defaultProps = {
    title: 'Foo title',
    tooltipTitle: 'Bar tooltipTitle',
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlTooltip,
        GlSprintf,
      },
    });
  };

  describe('tooltip', () => {
    it('the title is controlled by tooltipTitle prop', () => {
      mountComponent();
      const tooltip = findTooltip();
      expect(tooltip).toBeDefined();
      expect(tooltip.text()).toBe(defaultProps.tooltipTitle);
    });

    it('is disabled when tooltipTitle is disabled', () => {
      mountComponent({ tooltipDisabled: true });
      expect(findTooltip().props('disabled')).toBe(true);
    });

    it('works with a link', () => {
      mountComponent({
        tooltipTitle: LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION,
        tooltipLink: 'foo',
      });
      expect(findTooltip().text()).toMatchInterpolatedText(
        LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION,
      );
    });
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
