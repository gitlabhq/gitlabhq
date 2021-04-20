import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PackageIconAndName from '~/packages/shared/components/package_icon_and_name.vue';

describe('PackageIconAndName', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);

  const mountComponent = () => {
    wrapper = shallowMount(PackageIconAndName, {
      slots: {
        default: 'test',
      },
    });
  };

  it('has an icon', () => {
    mountComponent();

    const icon = findIcon();

    expect(icon.exists()).toBe(true);
    expect(icon.props('name')).toBe('package');
  });

  it('renders the slot content', () => {
    mountComponent();

    expect(wrapper.text()).toBe('test');
  });
});
