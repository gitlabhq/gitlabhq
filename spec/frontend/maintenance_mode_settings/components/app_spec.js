import { shallowMount } from '@vue/test-utils';
import MaintenanceModeSettingsApp from '~/maintenance_mode_settings/components/app.vue';
import { GlToggle, GlFormTextarea, GlDeprecatedButton } from '@gitlab/ui';

describe('MaintenanceModeSettingsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MaintenanceModeSettingsApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findMaintenanceModeSettingsContainer = () => wrapper.find('article');
  const findGlToggle = () => wrapper.find(GlToggle);
  const findGlFormTextarea = () => wrapper.find(GlFormTextarea);
  const findGlButton = () => wrapper.find(GlDeprecatedButton);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Maintenance Mode Settings container', () => {
      expect(findMaintenanceModeSettingsContainer().exists()).toBe(true);
    });

    it('renders the GlToggle', () => {
      expect(findGlToggle().exists()).toBe(true);
    });

    it('renders the GlFormTextarea', () => {
      expect(findGlFormTextarea().exists()).toBe(true);
    });

    it('renders the GlDeprecatedButton', () => {
      expect(findGlButton().exists()).toBe(true);
    });
  });
});
