import { mountExtended } from 'helpers/vue_test_utils_helper';
import VisibilityLevel from '~/organizations/settings/general/components/visibility_level.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';

describe('VisibilityLevel', () => {
  let wrapper;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
      path: 'foo-bar',
      description: 'foo bar',
      visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    },
  };

  const defaultPropsData = {
    id: 'organization-settings-visibility',
    expanded: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(VisibilityLevel, {
      provide: defaultProvide,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        SettingsBlock,
      },
    });
  };

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findVisibilityLevelRadioButtons = () => wrapper.findComponent(VisibilityLevelRadioButtons);

  beforeEach(() => {
    createComponent();
  });

  it('renders settings block with correct props and description', () => {
    expect(findSettingsBlock().props()).toEqual({ title: 'Visibility', ...defaultPropsData });
    expect(findSettingsBlock().text()).toContain('Choose organization visibility level.');
  });

  describe('when SettingsBlock component emits `toggle-expand` event', () => {
    beforeEach(() => {
      findSettingsBlock().vm.$emit('toggle-expand', true);
    });

    it('emits `toggle-expand` event', () => {
      expect(wrapper.emitted('toggle-expand')).toEqual([[true]]);
    });
  });

  it('renders visibility level field with the current visibility as the only option', () => {
    expect(findVisibilityLevelRadioButtons().props()).toEqual({
      checked: VISIBILITY_LEVEL_PRIVATE_INTEGER,
      visibilityLevels: [VISIBILITY_LEVEL_PRIVATE_INTEGER],
      visibilityLevelDescriptions: ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
    });
  });
});
