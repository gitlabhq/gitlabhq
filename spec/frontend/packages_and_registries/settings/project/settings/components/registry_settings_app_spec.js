import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';

describe('Registry Settings app', () => {
  let wrapper;
  const findContainerExpirationPolicy = () => wrapper.find(ContainerExpirationPolicy);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders container expiration policy component', () => {
    wrapper = shallowMount(component);

    expect(findContainerExpirationPolicy().exists()).toBe(true);
  });
});
