import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSettings from '~/organizations/settings/general/components/organization_settings.vue';
import VisibilityLevel from '~/organizations/settings/general/components/visibility_level.vue';
import AdvancedSettings from '~/organizations/settings/general/components/advanced_settings.vue';
import SearchSettings from '~/search_settings/components/search_settings.vue';
import App from '~/organizations/settings/general/components/app.vue';

describe('OrganizationSettingsGeneralApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(App);
  };

  const createSection = (id) => {
    const section = document.createElement('div');
    section.id = id;

    return section;
  };

  const findOrganizationSettingsSection = () => wrapper.findComponent(OrganizationSettings);
  const findVisibilitySection = () => wrapper.findComponent(VisibilityLevel);
  const findAdvancedSection = () => wrapper.findComponent(AdvancedSettings);
  const findSearchSettings = () => wrapper.findComponent(SearchSettings);

  beforeEach(() => {
    createComponent();
  });

  it('renders `Organization settings` section expanded by default', () => {
    expect(findOrganizationSettingsSection().props('expanded')).toBe(true);
  });

  it('renders `Visibility` section collapsed by default', () => {
    expect(findVisibilitySection().props('expanded')).toBe(false);
  });

  it('renders `Advanced` section collapsed by default', () => {
    expect(findAdvancedSection().props('expanded')).toBe(false);
  });

  describe('when `Organization settings` section emits `toggle-expand` event', () => {
    beforeEach(() => {
      findOrganizationSettingsSection().vm.$emit('toggle-expand', false);
    });

    it('collapses section', () => {
      expect(findOrganizationSettingsSection().props('expanded')).toBe(false);
    });
  });

  describe('when `Visibility` section emits `toggle-expand` event', () => {
    beforeEach(() => {
      findVisibilitySection().vm.$emit('toggle-expand', true);
    });

    it('expands section', () => {
      expect(findVisibilitySection().props('expanded')).toBe(true);
    });
  });

  describe('when `Advanced` section emits `toggle-expand` event', () => {
    beforeEach(() => {
      findAdvancedSection().vm.$emit('toggle-expand', true);
    });

    it('expands section', () => {
      expect(findAdvancedSection().props('expanded')).toBe(true);
    });
  });

  it('renders SearchSettings component with correct props', () => {
    expect(findSearchSettings().props()).toMatchObject({
      searchRoot: expect.any(Element),
      sectionSelector: '.vue-settings-block',
    });

    expect(findSearchSettings().props('isExpandedFn')(createSection('organization-settings'))).toBe(
      true,
    );
  });

  describe('when SearchSettings emits expand event', () => {
    beforeEach(() => {
      findSearchSettings().vm.$emit('expand', createSection('organization-settings-visibility'));
    });

    it('expands section', () => {
      expect(findVisibilitySection().props('expanded')).toBe(true);
    });
  });

  describe('when SearchSettings emits collapse event', () => {
    beforeEach(() => {
      findSearchSettings().vm.$emit('collapse', createSection('organization-settings'));
    });

    it('collapses section', () => {
      expect(findOrganizationSettingsSection().props('expanded')).toBe(false);
    });
  });
});
