import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/vue_shared/components/registry/details_row.vue';

describe('DetailsRow', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
      propsData: {
        icon: 'clock',
        ...props,
      },
      slots: {
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  it('has a default slot', () => {
    mountComponent();
    expect(findDefaultSlot().exists()).toBe(true);
  });

  describe('icon prop', () => {
    it('contains an icon', () => {
      mountComponent();
      expect(findIcon().exists()).toBe(true);
    });

    it('icon has the correct props', () => {
      mountComponent();
      expect(findIcon().props()).toMatchObject({
        name: 'clock',
      });
    });
  });

  describe('padding prop', () => {
    it('padding has a default', () => {
      mountComponent();
      expect(wrapper.classes('gl-py-2')).toBe(true);
    });

    it('is reflected in the template', () => {
      mountComponent({ padding: 'gl-py-4' });
      expect(wrapper.classes('gl-py-4')).toBe(true);
    });
  });

  describe('dashed prop', () => {
    const borderClasses = ['gl-border-b-solid', 'gl-border-default', 'gl-border-b-1'];
    it('by default component has no border', () => {
      mountComponent();
      expect(wrapper.classes).not.toEqual(expect.arrayContaining(borderClasses));
    });

    it('has a border when dashed is true', () => {
      mountComponent({ dashed: true });
      expect(wrapper.classes()).toEqual(expect.arrayContaining(borderClasses));
    });
  });
});
