import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IncidentsSettingTabs from '~/incidents_settings/components/incidents_settings_tabs.vue';

describe('IncidentsSettingTabs', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(IncidentsSettingTabs, {
      provide: {
        service: {},
        serviceLevelAgreementSettings: {},
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findToggleButton = () => wrapper.find({ ref: 'toggleBtn' });
  const findSectionHeader = () => wrapper.find({ ref: 'sectionHeader' });

  const findIntegrationTabs = () => wrapper.findAll(GlTab);
  it('renders header text', () => {
    expect(findSectionHeader().text()).toBe('Incidents');
  });

  describe('expand/collapse button', () => {
    it('renders as an expand button by default', () => {
      expect(findToggleButton().text()).toBe('Expand');
    });
  });

  it('should render the component', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should render the tab for each active integration', () => {
    const activeTabs = wrapper.vm.$options.tabs.filter((tab) => tab.active);
    expect(findIntegrationTabs().length).toBe(activeTabs.length);
    activeTabs.forEach((tab, index) => {
      expect(findIntegrationTabs().at(index).attributes('title')).toBe(tab.title);
      expect(
        findIntegrationTabs().at(index).find(`[data-testid="${tab.component}-tab"]`).exists(),
      ).toBe(true);
    });
  });
});
