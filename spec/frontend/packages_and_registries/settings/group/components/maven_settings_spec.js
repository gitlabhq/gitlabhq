import { shallowMount } from '@vue/test-utils';
import MavenSettings from '~/packages_and_registries/settings/group/components/maven_settings.vue';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

describe('maven_settings', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(MavenSettings, {
      scopedSlots: {
        default: '<div data-testid="default-slot">{{props.modelNames}}</div>',
      },
    });
  };

  const findSettingsTitle = () => wrapper.findComponent(SettingsTitles);
  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('title component', () => {
    it('has a title component', () => {
      mountComponent();

      expect(findSettingsTitle().exists()).toBe(true);
    });

    it('passes the correct props', () => {
      mountComponent();

      expect(findSettingsTitle().props()).toMatchObject({
        title: 'Maven',
        subTitle: 'Settings for Maven packages',
      });
    });
  });

  describe('default slot', () => {
    it('accept a default slots', () => {
      mountComponent();

      expect(findDefaultSlot().exists()).toBe(true);
    });

    it('binds model names', () => {
      mountComponent();

      expect(findDefaultSlot().text()).toContain('mavenDuplicatesAllowed');
      expect(findDefaultSlot().text()).toContain('mavenDuplicateExceptionRegex');
    });
  });
});
