import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AdvancedSettings from '~/organizations/settings/general/components/advanced_settings.vue';
import ChangeUrl from '~/organizations/settings/general/components/change_url.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

describe('AdvancedSettings', () => {
  let wrapper;
  const createComponent = () => {
    wrapper = shallowMountExtended(AdvancedSettings);
  };

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);

  beforeEach(() => {
    createComponent();
  });

  it('renders settings block', () => {
    expect(findSettingsBlock().exists()).toBe(true);
  });

  it('renders `ChangeUrl` component', () => {
    expect(findSettingsBlock().findComponent(ChangeUrl).exists()).toBe(true);
  });
});
