import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSettings from '~/organizations/settings/general/components/organization_settings.vue';
import VisibilityLevel from '~/organizations/settings/general/components/visibility_level.vue';
import AdvancedSettings from '~/organizations/settings/general/components/advanced_settings.vue';
import App from '~/organizations/settings/general/components/app.vue';

describe('OrganizationSettingsGeneralApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(App);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders `Organization settings` section', () => {
    expect(wrapper.findComponent(OrganizationSettings).exists()).toBe(true);
  });

  it('renders `Visibility` section', () => {
    expect(wrapper.findComponent(VisibilityLevel).exists()).toBe(true);
  });

  it('renders `Advanced` section', () => {
    expect(wrapper.findComponent(AdvancedSettings).exists()).toBe(true);
  });
});
