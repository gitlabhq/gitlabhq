import { shallowMount } from '@vue/test-utils';
import GenericSettings from '~/packages_and_registries/settings/group/components/generic_settings.vue';
import SettingsTitles from '~/packages_and_registries/settings/group/components/settings_titles.vue';

describe('generic_settings', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(GenericSettings, {
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
        title: 'Generic',
        subTitle: 'Settings for Generic packages',
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

      expect(findDefaultSlot().text()).toContain('genericDuplicatesAllowed');
      expect(findDefaultSlot().text()).toContain('genericDuplicateExceptionRegex');
    });
  });
});
