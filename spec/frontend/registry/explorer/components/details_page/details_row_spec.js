import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import component from '~/registry/explorer/components/details_page/details_row.vue';

describe('DetailsRow', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      propsData: {
        icon: 'clock',
      },
      slots: {
        default: '<div data-testid="default-slot"></div>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

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

  it('has a default slot', () => {
    mountComponent();
    expect(findDefaultSlot().exists()).toBe(true);
  });
});
