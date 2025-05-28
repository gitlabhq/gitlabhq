import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AdvancedSettings from '~/organizations/settings/general/components/advanced_settings.vue';
import ChangeUrl from '~/organizations/settings/general/components/change_url.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

describe('AdvancedSettings', () => {
  let wrapper;

  const defaultPropsData = {
    id: 'organization-settings-advanced',
    expanded: false,
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(AdvancedSettings, { propsData: defaultPropsData });
  };

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);

  beforeEach(() => {
    createComponent();
  });

  it('renders settings block with correct props', () => {
    expect(findSettingsBlock().props()).toEqual({ title: 'Advanced', ...defaultPropsData });
  });

  it('renders `ChangeUrl` component', () => {
    expect(findSettingsBlock().findComponent(ChangeUrl).exists()).toBe(true);
  });

  describe('when SettingsBlock component emits `toggle-expand` event', () => {
    beforeEach(() => {
      findSettingsBlock().vm.$emit('toggle-expand', true);
    });

    it('emits `toggle-expand` event', () => {
      expect(wrapper.emitted('toggle-expand')).toEqual([[true]]);
    });
  });
});
