import { GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IncidentsSettingTabs from '~/incidents_settings/components/incidents_settings_tabs.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { INTEGRATION_TABS_CONFIG } from '~/incidents_settings/constants';

describe('IncidentsSettingTabs', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMountExtended(IncidentsSettingTabs, {
      provide: {
        service: {},
        serviceLevelAgreementSettings: {},
      },
      stubs: {
        SettingsBlock,
      },
    });
  });

  const findToggleButton = () => wrapper.findByTestId('settings-block-toggle');
  const findSectionHeader = () => wrapper.findByTestId('settings-block-title');
  const findIntegrationTabs = () => wrapper.findAllComponents(GlTab);
  const findIntegrationTabAt = (index) => findIntegrationTabs().at(index);
  const findTabComponent = (tab) => wrapper.findByTestId(`${tab.component}-tab`);

  it('renders header text', () => {
    expect(findSectionHeader().text()).toBe('Incidents');
  });

  describe('expand/collapse button', () => {
    it('renders as an expand button by default', () => {
      expect(findToggleButton().attributes('aria-label')).toContain('Expand');
    });
  });

  it('should render the tab for each active integration', () => {
    const activeTabs = INTEGRATION_TABS_CONFIG.filter((tab) => tab.active);
    expect(findIntegrationTabs()).toHaveLength(activeTabs.length);

    activeTabs.forEach((tab, index) => {
      expect(findIntegrationTabAt(index).attributes('title')).toBe(tab.title);
      expect(findTabComponent(tab).exists()).toBe(true);
    });
  });
});
