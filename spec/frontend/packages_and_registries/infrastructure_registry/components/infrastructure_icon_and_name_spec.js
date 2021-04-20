import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import InfrastructureIconAndName from '~/packages_and_registries/infrastructure_registry/components/infrastructure_icon_and_name.vue';

describe('InfrastructureIconAndName', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);

  const mountComponent = () => {
    wrapper = shallowMount(InfrastructureIconAndName, {});
  };

  it('has an icon', () => {
    mountComponent();

    const icon = findIcon();

    expect(icon.exists()).toBe(true);
    expect(icon.props('name')).toBe('infrastructure-registry');
  });

  it('has the type fixed to terraform', () => {
    mountComponent();

    expect(wrapper.text()).toBe('Terraform');
  });
});
