import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('DetailsRow', () => {
  let wrapper;

  const defaultProps = {
    icon: 'clock',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(DetailsRow, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      slots: {
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findDefaultSlot = () => wrapper.findByTestId('default-slot');

  it('has a default slot', () => {
    createComponent();
    expect(findDefaultSlot().exists()).toBe(true);
  });

  describe('icon prop', () => {
    it('contains an icon', () => {
      createComponent();
      expect(findIcon().exists()).toBe(true);
    });

    it('icon has the correct props', () => {
      createComponent();
      expect(findIcon().props()).toMatchObject({
        name: 'clock',
      });
    });
  });

  describe('padding prop', () => {
    it('padding has a default', () => {
      createComponent();
      expect(wrapper.classes('gl-py-2')).toBe(true);
    });

    it('is reflected in the template', () => {
      createComponent({ padding: 'gl-py-4' });
      expect(wrapper.classes('gl-py-4')).toBe(true);
    });
  });

  describe('dashed prop', () => {
    const borderClasses = ['gl-border-b-solid', 'gl-border-default', 'gl-border-b-1'];
    it('by default component has no border', () => {
      createComponent();
      expect(wrapper.classes).not.toEqual(expect.arrayContaining(borderClasses));
    });

    it('has a border when dashed is true', () => {
      createComponent({ dashed: true });
      expect(wrapper.classes()).toEqual(expect.arrayContaining(borderClasses));
    });
  });
});
