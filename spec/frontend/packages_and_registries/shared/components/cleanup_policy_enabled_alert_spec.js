import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from '~/packages_and_registries/shared/components/cleanup_policy_enabled_alert.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('CleanupPolicyEnabledAlert', () => {
  let wrapper;

  const defaultProps = {
    projectPath: 'foo',
    cleanupPoliciesSettingsPath: 'label-bar',
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
      stubs: {
        LocalStorageSync,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('when dismissed is not visible', async () => {
    mountComponent();

    expect(findAlert().exists()).toBe(true);
    findAlert().vm.$emit('dismiss');

    await nextTick();

    expect(findAlert().exists()).toBe(false);
  });
});
